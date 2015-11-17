local cjson = require('cjson')
local http = require('httpclient').new()
local inspect = require('inspect')
local posix = require('posix')
local signal = require('posix.signal')
local unistd = require('posix.unistd')
local etlua = require('etlua')
local std = require('std')

local optparse = std.optparse [[
  siren-balancer 0.1.0-alpha

  This program comes with ABSOLUTELY NO WARRANTY.

  Usage: siren-balancer [<options>]

  Options:

    -h, --help              display this help, then exit
        --version           display version information, then exit
    -s, --service=SERVICE   service name to discover backends for
    -p, --port=PORT         service port to discover backends for
    -i, --interval=5        poll interval for discovery in seconds
]]

local arg, opts = optparse:parse(arg, {interval=5})

for i, opt in ipairs({'service', 'port'}) do
  if opts[opt] == nil then
    optparse:opterr("option '" .. opt .. "' must be specified")
  end
end

local template_file = io.open('haproxy.cfg.tmpl')
local template = etlua.compile(template_file:read('*a'))
template_file:close()

while true do
  local backends = {}
  local res = http:get('http://discover:8080/v1/services/' .. opts.service)

  if res.body ~= nil and res.code == 200 then
    local services = cjson.decode(res.body)
    if #services[opts.service] > 0 then
      for i, container in ipairs(services[opts.service] or {}) do
        if container.interface[opts.port] then
          table.insert(backends, {
            name=container.id,
            addr=container.interface[opts.port]
          })
        end
      end
    end

    local haproxy_config = template({
      service_name=opts.service,
      port=opts.port,
      backends=backends})

    local config_file = io.open('/etc/haproxy.cfg', 'w')
    config_file:write(haproxy_config)
    config_file:close()

    os.execute('./reload-haproxy.sh')
  else
    print('Failed to get a successful response from siren-discover')
  end

  os.execute('sleep ' .. opts.interval)
end
