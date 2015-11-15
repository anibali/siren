#!/bin/bash -e

cd /app

docker-gen -interval 10 -watch \
  -notify "lua notify.lua" notify.lua.tmpl notify.lua
