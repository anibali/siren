local cjson = require('cjson')
local http = require('httpclient').new()
local inspect = require('inspect')
local posix = require('posix')
local signal = require('posix.signal')
local unistd = require('posix.unistd')

local group_name = arg[1]
local service_port = arg[2]

local socat_pid

function fork_socat(port, dest)
  -- If socat is running, terminate it
  if socat_pid then
    signal.kill(socat_pid, signal.SIGTERM)
    posix.wait(socat_pid)
  end

  -- Fork a new process
  local pid = posix.fork()

  -- Child process
  if pid == 0 then
    unistd.execp('socat', {
      'TCP4-LISTEN:' .. port .. ',fork,reuseaddr',
      'TCP4:' .. dest})

    os.exit(0)
  end

  socat_pid = pid
end

local dest_addr

while true do
  local res = http:get('http://discover:8080/v1/services/' .. group_name)

  if res.body ~= nil and res.code == 200 then
    local services = cjson.decode(res.body)
    if #services[group_name] > 0 then
      local dest_addr_changed = true
      if dest_addr then
        for i, service in ipairs(services[group_name]) do
          if service.interface[service_port] == dest_addr then
            dest_addr_changed = false
            break
          end
        end
      end

      if dest_addr_changed then
        dest_addr = services[group_name][1].interface[service_port]
        print('Destination set to: ' .. dest_addr)
        fork_socat(service_port, dest_addr)
      end
    end
  end

  os.execute('sleep 5')
end
