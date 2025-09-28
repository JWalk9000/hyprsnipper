#!/bin/bash
# HyprSnipper launcher script
cd "$(dirname "$0")/src"
exec python3 main.py "$@"
