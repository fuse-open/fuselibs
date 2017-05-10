#!/bin/bash

if [ $# -ne 1 ]; then
    echo "USAGE: $0 <version>"
    exit 1
fi

version=$1
version_file=`dirname "$0"`"/TestApp.ux"
unoproj_file=`dirname "$0"`"/ManualTestingApp.unoproj"

echo "Setting version to $version in $version_file"
sed -i '' "s/0.0.0.0/$version/" "$version_file"

echo "Setting version to $version in $unoproj_file"
sed -i '' "s/0.0.0.0/$version/" "$unoproj_file"
