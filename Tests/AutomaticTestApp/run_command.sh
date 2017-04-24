#!/bin/bash
set -e

if [ "$OSTYPE" == msys ]; then
    TIMEOUT_CMD=timeout
else
    if ! which -s gtimeout; then
        echo "Please do 'brew install coreutils' to get 'gtimeout'"
        exit 1
    fi
    TIMEOUT_CMD=gtimeout
fi

if [ $# -lt 2 ]; then
    echo "USAGE: $0 <timeout> <command> [<parameters to command>]"
    exit 1
fi

TIMEOUT=$1
shift
COMMAND=$*
UNO_PID=auto_test_app_uno.pid

echo "Timeout: '$TIMEOUT'"
echo "Command: '$COMMAND'"

function parse_stdout()
{
    while read data; do
        data=$(echo "$data" | sed "s/$(printf '\r')*\$//") #Remove \r that we get from console.log
        if [[ "$data" == *"TEST_APP_MSG:OK" ]]; then
            kill -s 2 $(<$UNO_PID)
            return 0
        elif [[ "$data" == *"TEST_APP_MSG:ERROR" ]]; then
            kill -s 2 $(<$UNO_PID)
            return 1
        else
            echo "> $data"
        fi
    done
    return 1
}

function failed()
{
    echo "Test app failed!"
    exit 1
}

echo "Starting app"
($TIMEOUT_CMD $TIMEOUT $COMMAND & echo $! >&3) 3>$UNO_PID | parse_stdout || failed

echo "Test app succeeded!"
