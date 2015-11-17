local cjson = require('cjson')
local http = require('httpclient').new()
local inspect = require('inspect')
local posix = require('posix')
local signal = require('posix.signal')
local unistd = require('posix.unistd')
local etlua = require('etlua')

if #arg ~= 2 then
  print('Usage: lua balancer.lua service_name service_port')
  print()
  print('service_name = value of _SIREN_SERVICE set on containers in service')
  print('service_port = port number to balance')
  print()
  print('error: wrong number of arguments')
  os.exit(1)
end

local service_name = arg[1]
local port = arg[2]

local template_file = io.open('haproxy.cfg.tmpl')
local template = etlua.compile(template_file:read('*a'))
template_file:close()

while true do
  local backends = {}
  local res = http:get('http://discover:8080/v1/services/' .. service_name)

  if res.body ~= nil and res.code == 200 then
    local services = cjson.decode(res.body)
    if #services[service_name] > 0 then
      for i, container in ipairs(services[service_name] or {}) do
        if container.interface[port] then
          table.insert(backends, {
            name=container.id,
            addr=container.interface[port]
          })
        end
      end
    end

    local haproxy_config = template({
      service_name=service_name,
      port=port,
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
