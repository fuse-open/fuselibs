#!/bin/sh

case "$(uname -s)" in
    CYGWIN*|MINGW32*|MINGW64*|MSYS*)
        clr=
        ;;
    *)
        clr=mono
        ;;
esac

set -e
cd "`dirname "$0"`"

$clr Stuff/stuff.exe install Stuff
$clr Stuff/uno.exe doctor $*
