local cjson = require('cjson')
local http = require('httpclient').new()
local inspect = require('inspect')
local posix = require('posix')
local signal = require('posix.signal')
local unistd = require('posix.unistd')
local etlua = require('etlua')

local group_name = arg[1]
local service_port = arg[2]

local template_file = io.open('haproxy.cfg.tmpl')
local template = etlua.compile(template_file:read('*a'))
template_file:close()

while true do
  local backends = {}
  local res = http:get('http://discover:8080/v1/services/' .. group_name)

  if res.body ~= nil and res.code == 200 then
    local services = cjson.decode(res.body)
    if #services[group_name] > 0 then
      for i, service in ipairs(services[group_name] or {}) do
        if service.interface[service_port] then
          table.insert(backends, {
            name=service.id,
            addr=service.interface[service_port]
          })
        end
      end
    end

    local haproxy_config = template({
      group_name=group_name,
      port=service_port,
      backends=backends})

    local config_file = io.open('/etc/haproxy.cfg', 'w')
    config_file:write(haproxy_config)
    config_file:close()

    os.execute('./reload-haproxy.sh')
  else
    print('Failed to get a successful response from siren-discover')
  end

  os.execute('sleep 5')
end
