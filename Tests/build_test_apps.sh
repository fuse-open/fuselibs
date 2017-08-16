#!/bin/bash
set -e
cd "`dirname "$0"`"

function usage()
{
    echo "USAGE: $0 <build_number>"
}

if [ $# != 1 ]; then
    usage
    exit 1
fi

VERSION=$1

# Manual test app

pushd ManualTests/ManualTestingApp

echo "Setting version to $VERSION in manual test app"
./set_version.sh $VERSION

echo "Building manual test app for Android"
../../../Stuff/uno build ManualTestingApp.unoproj -v --target=android --output-dir=.build/Android-Debug

echo "Building manual test app for iOS"
echo "Note that this requires the keychain to be unlocked, build servers might need a separate step for this"
../../../Stuff/uno build ManualTestingApp.unoproj -v --target=ios --output-dir=.build/iOS-Debug
xcodebuild -project .build/iOS-Debug/*.xcodeproj -configuration Release
/usr/bin/xcrun -sdk iphoneos PackageApplication -v .build/iOS-Debug/build/Release-iphoneos/*.app -o "$PWD/ManualTestingApp.ipa" --embed /Users/outracks/Library/MobileDevice/Provisioning\ Profiles/Adhoc.mobileprovision

popd

# Native test app

pushd ManualTests/NativeTestingApp

echo "Building native test app for Android"
../../../Stuff/uno build -v --target=android --output-dir=.build/Android-Debug

echo "Building native test app for iOS"
echo "Note that this requires the keychain to be unlocked, build servers might need a separate step for this"
../../../Stuff/uno build -v --target=ios --output-dir=.build/iOS-Debug
xcodebuild -project .build/iOS-Debug/*.xcodeproj -configuration Release
/usr/bin/xcrun -sdk iphoneos PackageApplication -v .build/iOS-Debug/build/Release-iphoneos/*.app -o "$PWD/NativeTestingApp.ipa" --embed /Users/outracks/Library/MobileDevice/Provisioning\ Profiles/Adhoc.mobileprovision

popd

