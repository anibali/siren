#!/bin/bash -e

cd /app

lua balancer.lua "$@"
