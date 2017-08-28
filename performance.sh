#!/bin/sh
set -e
cd "`dirname "$0"`"

"$ROOT/Stuff/uno" perf-test -logdirectory=PerfLogs Source
