#!/bin/sh
trap 'echo PACK FAILED!; exit 1' ERR
SELF=`echo $0 | sed 's/\\\\/\\//g'`
cd "`dirname "$SELF"`" || exit 1
PATH="Stuff:$PATH"
OUT="upload"

VERSION=$(cat VERSION.txt)

# Detect revision
if [ -n "$BUILD_VCS_NUMBER" ]; then
    REVISION=`echo "$BUILD_VCS_NUMBER" | cut -c1-7`
else
    REVISION=`git rev-parse --short HEAD`
fi

# Detect branch
if [ -z "$BRANCH" ]; then
    BRANCH=`git rev-parse --abbrev-ref HEAD`
fi

# Disable suffix on release branches, otherwise
# use commit SHA as prerelease suffix
case $BRANCH in
release-*)
    UNO_SUFFIX=
    STUFF_SUFFIX="--suffix=-$VERSION"
    ;;
master)
    UNO_SUFFIX="--suffix=master-$REVISION"
    STUFF_SUFFIX="--suffix=-$VERSION-master-$REVISION"
    ;;
*)
    UNO_SUFFIX="--suffix=dev-$REVISION"
    STUFF_SUFFIX="--suffix=-$VERSION-dev-$REVISION"
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
            --out-dir="$OUT" \
            $UNO_SUFFIX
    fi
done

stuff pack Tests/AutomaticTestApp \
    --name=AutomaticTestApp \
    $STUFF_SUFFIX \
    --output-dir=AutomaticTestAppUpload
