#!/bin/sh

if [ $# -lt 1 -o $# -gt 2 -o "$1" == "-h" ]; then 
    echo "USAGE: $0 <target> [<path to uno.exe>]"
    exit 1
fi

DIR=$(dirname "$0")

TARGET=$1

UNO=$DIR/../Stuff/uno.exe
if [ $# == 2 ]; then
    UNO=$2
fi

if [ "$OSTYPE" != "msys" ]; then
    if which mono64 > /dev/null 2>&1; then
        UNO="mono64 $UNO"
    else
        UNO="mono $UNO"
    fi
fi

shopt -s nocasematch
if [ "$TARGET" == "android" -o "$TARGET" == "ios" ]; then
    TIMEOUT=600
else
    TIMEOUT=100
fi

echo "Testing automatic test app on target '$TARGET', using Uno '$UNO' and timeout '$TIMEOUT'"

$DIR/AutomaticTestApp/run_command.sh $TIMEOUT $UNO build -t$TARGET -r $DIR/AutomaticTestApp/App/App.unoproj
