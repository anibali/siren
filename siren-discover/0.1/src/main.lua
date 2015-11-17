local inspect = require('inspect')
local cjson = require('cjson')
local xavante = require('xavante')

-- Time in seconds to cache etcd response
local CACHE_VALID_TIME = 5

-- Initialize etcd client
local etcd
if os.getenv('ETCD_ADDR') then
  etcd = require('etcd').new(os.getenv('ETCD_ADDR'))
else
  etcd = require('etcd').new()
end

local function treeify(json, prefix)
  prefix = prefix or '/'
  local node = {}
  local key = json.key:sub(prefix:len() + 1)
  local value
  if json.dir then
    value = {}
    for i, child in ipairs(json.nodes or {}) do
      table.insert(value, treeify(child, json.key .. '/'))
    end
  else
    value = json.value
  end
  node[key] = value
  return node
end

local function niceify(tree)
  local groups = {}
  for k, group_info in ipairs(tree) do
    for group_name, containers in pairs(group_info) do
      group = {}
      for i, container_info in ipairs(containers) do
        for id, info in pairs(container_info) do
          service = {id=id, params={}, interface={}}
          for l, entry in ipairs(info) do
            for field, data in pairs(entry) do
              if field == 'params' then
                for j, param_info in ipairs(data) do
                  for key, value in pairs(param_info) do
                    service.params[key] = value
                  end
                end
              end
              if field == 'interface' then
                for j, interface_info in ipairs(data) do
                  for port, host_addr in pairs(interface_info) do
                    service.interface[port] = host_addr
                  end
                end
              end
            end
          end
          table.insert(group, service)
        end
      end
      groups[group_name] = group
    end
  end
  return groups
end

-- Function for listing running services
local cache
local cache_updated_at = 0
local function get_services()
  local now = os.time()
  if now - cache_updated_at > CACHE_VALID_TIME then
    cache = nil
  end
  if cache == nil then
    local etcd_response = etcd:get('/siren/', {recursive=true})
    if etcd_response and etcd_response.node then
      cache = niceify(treeify(etcd_response.node).siren)
      cache_updated_at = now
    end
  end
  return cache
end

require('xavante.httpd').errorhandler = function(msg, co, skt)
    msg = tostring(msg)
        io.stderr:write('  Internal server error: ' .. msg .. '\n',
          '  ' .. tostring(co) .. '\n',
          '  ' .. tostring(skt) .. '\n')
        skt:send('HTTP/1.0 500 Internal Server Error\r\n')
        skt:send(string.format('Date: %s\r\n\r\n', os.date('!%a, %d %b %Y %H:%M:%S GMT')))
        skt:send(string.format([[
<html><head><title>Internal server error</title></head>
<body>
<h1>Internal server error</h1>
<p>%s</p>
</body></html>
]], string.gsub(msg, '\n', '<br/>\n')))
end

-- Set up server routes
xavante.HTTP {
  server = {host = '*', port = 8080},

  defaultHost = {
    rules = {
      {
        match = '^/v1/services/?$',
        with = function(req, res)
          res.headers['Content-Type'] = 'application/json'
          res.content = cjson.encode(get_services() or {})
          return res
        end,
      },
      {
        match = '^/v1/services/([^/]*)/?$',
        with = function(req, res)
          local group_name = string.match(req.relpath, '^/v1/services/([^/]*)/?$')
          res.headers['Content-Type'] = 'application/json'
          res.content = cjson.encode({[group_name]=get_services()[group_name] or {}})
          return res
        end,
      },
      {
        match = '.',
        with = function(req, res)
          res.statusline = "HTTP/1.1 404 Not Found"
          res.headers['Content-Type'] = 'text/plain'
          res.content = 'Not found.'
          return res
        end,
      }
    }
  }
}

-- Start the server
xavante.start()
