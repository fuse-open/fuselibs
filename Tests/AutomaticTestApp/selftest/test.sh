#!/bin/bash
cd $(dirname $0)

function green()
{
    echo -e "\033[0;32m$1\033[0m"
}

function blue()
{
    echo -e "\033[0;34m$1\033[0m"
}

function red()
{
    echo -e "\033[0;31m$1\033[0m"
}

function die()
{
    red "ERROR: $1"
    exit 1
}

blue "\nSCENARIO: App prints TEST_APP_MSG:OK before timeout"
../run_command.sh 1 ./mock.sh TEST_APP_MSG:OK 0 || die "Expected success, but failed"

blue "\nSCENARIO: App prints TEST_APP_MSG:ERROR before timeout"
../run_command.sh 1 ./mock.sh TEST_APP_MSG:ERROR 0 && die "Expected failure, got success"

blue "\nSCENARIO: App doesn't return before timeout"
../run_command.sh 1 ./mock.sh doesnt_matter 2 && die "Expected failure, got success"

blue "\nSCENARIO: App returns before timeout without printing status"
../run_command.sh 1 ./mock.sh no_status_printed 0 && die "Expected failure, got success"

green "\nALL TESTS PASSED"
