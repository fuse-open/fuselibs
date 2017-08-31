#!/bin/sh
set -e

ROOT=`dirname $0`

"$ROOT/Stuff/uno" test "$ROOT/Source"

"$ROOT/Tests/package-compilation.sh"
