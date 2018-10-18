#!/bin/sh
trap 'echo PACK FAILED!; exit 1' ERR
SELF=`echo $0 | sed 's/\\\\/\\//g'`
cd "`dirname "$SELF"`" || exit 1
PATH="Stuff:$PATH"
OUT="upload"

VERSION=$(cat VERSION.txt)

# Detect branch and revision
REVISION=`git rev-parse --short HEAD`
BRANCH=`git rev-parse --abbrev-ref HEAD`

# Disable suffix on release branches, otherwise
# use commit SHA as prerelease suffix
case $BRANCH in
release-*)
    ;;
master)
    VERSION="$VERSION-master-$REVISION"
    ;;
*)
    VERSION="$VERSION-dev-$REVISION"
    ;;
esac

uno doctor --configuration=Release --build-number=$VERSION

# Make packages
for f in Source/*; do
    name=`basename "$f"`
    project=$f/$name.unoproj
    if [ -f "$project" ]; then
        uno pack "$project" \
            --version=$VERSION \
            --out-dir="$OUT"
    fi
done
