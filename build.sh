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

nuget install -ConfigFile Stuff/NuGet.config -OutputDirectory Stuff -ExcludeVersion Stuff/packages.config
$clr Stuff/uno.exe doctor $*
