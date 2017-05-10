#!/bin/sh
set -e

ROOT=`dirname $0`

mono "$ROOT/Stuff/uno.exe" test "$ROOT/Source"

$ROOT/Tests/package-compilation.sh
