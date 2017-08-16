#!/bin/sh
set -e


ROOT=`dirname $0`"/.."
TARGET='(default)'
if [ "$OSTYPE" = msys ]; then
    OUTPUT_DIR="$TEMP/PackageCompilationTest"
else
    OUTPUT_DIR="/tmp/PackageCompilationTest"
fi
UNO="$ROOT/Stuff/uno.exe"
PACKAGES="$ROOT/Source/build"
ARGUMENTS=""


function die {
    echo "ERROR: $1"
    exit 1
}

function usage {
    echo "USAGE: $0 [options]"
    echo
    echo "    -t, --target <target>                build target (default: '$TARGET')"
    echo "    -o, --output <output dir>            output directory to store the generated project (default: '$OUTPUT_DIR')"
    echo "    -u, --uno <uno.exe location>         location of uno.exe (default: '$UNO')"
    echo "    -p, --packages <packages directory>  location of packages to compile (default: '$PACKAGES')"
    echo "    -a, --argument <uno argument>        extra argument to uno.exe (use -a <arg1> -a <arg2> ... to add more arguments)"
}

function monow {
    if [ "$OSTYPE" = msys ]; then
        "$@"
    elif which mono64 > /dev/null 2>&1; then
        mono64 "$@"
    else
        mono "$@"
    fi
}

if [[ "$1" == "-h" || "$1" == "--help" ]]
then
    usage
    exit 0
fi

while [[ $# -gt 1 ]]
do
    case $1 in
        -t|--target)
            TARGET=$2
            shift
        ;;
        -o|--output)
            OUTPUT_DIR=$2
            shift
        ;;
        -u|--uno)
            UNO=$2
            shift
        ;;
        -p|--packages)
            PACKAGES=$2
            shift
        ;;
        -a|--arguments)
            ARGUMENTS="$ARGUMENTS $2"
            shift
        ;;
        *)
            die "Unknown option $1"
        ;;
    esac
    shift
done

if [[ $# -gt 0 ]]
then
    die "Unknown option $1"
fi


echo "Testing compilation of packages"
echo "Target:          '$TARGET'"
echo "Uno:             '$UNO'"
echo "Output dir:      '$OUTPUT_DIR'"
echo "Packages dir:    '$PACKAGES'"
echo "Extra arguments: '$ARGUMENTS'"
echo


echo "Removing old project..."
if [ -d $OUTPUT_DIR ]; then
    rm -r $OUTPUT_DIR
fi

echo "Generating project..."
echo
monow $UNO test-gen $PACKAGES $OUTPUT_DIR

echo "Building project..."
echo
monow $UNO build -v --target=$TARGET --no-strip --clean $ARGUMENTS $OUTPUT_DIR
