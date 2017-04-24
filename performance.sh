#!/bin/sh
set -e
cd "`dirname "$0"`"

mono "$ROOT/Stuff/uno.exe" perf-test -logdirectory=PerfLogs Source
