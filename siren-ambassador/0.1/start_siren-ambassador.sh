#!/bin/bash -e

cd /app

lua ambassador.lua "$@"
