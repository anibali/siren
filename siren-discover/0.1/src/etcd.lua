local cjson = require('cjson')
local http = require('httpclient').new()
local inspect = require('inspect')

local M = {}
local Etcd = {}

local function to_query(data)
  local entries = {}
  for k, v in pairs(data) do
    if v ~= nil then
      table.insert(entries, k .. '=' .. tostring(v))
    end
  end
  return table.concat(entries, '&')
end

function Etcd:get(key, opts)
  opts = opts or {}
  local res = http:get(self.addr .. '/v2/keys/' .. key .. '?' .. to_query(opts))
  assert(res.body ~= nil, res.err)
  return cjson.decode(res.body)
end

function Etcd:set(key, value, opts)
  local data = {}
  data.value = value

  opts = opts or {}
  if opts.ttl then data.ttl = opts.ttl end
  if opts.dir then data.dir = opts.dir end
  if opts.prevExist then data.prevExist = opts.prevExist end
  if opts.recursive then data.recursive = opts.recursive end

  local res = http:put(self.addr .. '/v2/keys/' .. key,
    to_query(data),
    {content_type="application/x-www-form-urlencoded"})
  print(to_query(data))
  assert(res.body ~= nil, res.err)
  return cjson.decode(res.body)
end

function M.new(addr)
  local self = {}
  self.addr = addr or 'http://127.0.0.1:2379'

  setmetatable(self, {__index = Etcd})
  return self
end

return M
