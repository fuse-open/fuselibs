#!/bin/sh

if [ $# != 2 ]; then
    echo "USAGE: $0 <result string> <sleep time>"
fi
echo TEST_APP_MSG:START
sleep $2
echo $1
