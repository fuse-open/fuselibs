#!/bin/sh
trap 'echo PACK FAILED!; exit 1' ERR
SELF=`echo $0 | sed 's/\\\\/\\//g'`
cd "`dirname "$SELF"`" || exit 1
PATH="Stuff:$PATH"
OUT="upload"

# Detect version
if [ -n "$RELEASE_VERSION" ]; then
    VERSION="$RELEASE_VERSION"
else
    VERSION=$(cat VERSION.txt)"-local"
fi

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
    SUFFIX=
    ;;
master)
    SUFFIX="--suffix=master-$REVISION"
    ;;
*)
    SUFFIX="--suffix=$REVISION"
    ;;
esac

stuff install Stuff
bash Stuff/Devtools/update-version-numbers.sh --verify
uno doctor --configuration=Release

# Make packages
for f in Source/*; do
    name=`basename "$f"`
    project=$f/$name.unoproj
    if [ -f "$project" ]; then
        uno pack "$project" \
            --out-dir="$OUT" \
            $SUFFIX
    fi
done

stuff pack ProjectTemplates \
    --name=ProjectTemplates \
    --suffix=-$VERSION \
    --output-dir=ProjectTemplatesUpload

stuff pack Tests/AutomaticTestApp \
    --name=AutomaticTestApp \
    --suffix=-$VERSION \
    --output-dir=AutomaticTestAppUpload

# Build standalone release
mkdir -p release
rm -rf release/*

echo "Copying files to release/"
cp -Rf Source/build \
    Stuff/*.packages \
    Stuff/.unopath \
    Stuff/uno \
    Stuff/uno.exe \
    Stuff/uno.stuff \
    Stuff/stuff \
    Stuff/stuff.exe \
    release

unoconfig=`cat Stuff/.unoconfig`
unoconfig=${unoconfig/'../Source'/'.'}
echo "$unoconfig" > release/.unoconfig
