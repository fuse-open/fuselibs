#!/bin/bash

UNOPROJS=`find . -name '*.unoproj'`

OUTPUT="dependencies.gv"
IMAGE="dependencies.png"

rm -f "$OUTPUT"
rm -f "$IMAGE"

echo "digraph dependencies {" > $OUTPUT

for PROJ in $UNOPROJS; do
    NAME=$(echo $PROJ | awk -F/ '{print $NF}' | sed 's/.unoproj//')
    SUBDIR=$(echo $PROJ | awk -F/ '{print $3}')
    echo "Processing $NAME ($PROJ)"
    if [ "$SUBDIR" == "Tests" ]; then
        echo "    Skipping test project"
        continue
    fi
    DEPS=$(grep ".unoproj" $PROJ)
    for DEP in $DEPS; do
        DEP_NAME=$(echo $DEP | awk -F/ '{print $NF}' | sed 's/.unoproj[",]*//')
        echo " $(echo $NAME | sed 's/\./_/g') -> $(echo $DEP_NAME | sed 's/\./_/g');" >> "$OUTPUT.tmp"
    done
done


cat "$OUTPUT.tmp" | sort | uniq >> "$OUTPUT"

rm "$OUTPUT.tmp"

echo "}" >> $OUTPUT

dot -Tpng "$OUTPUT" -o "$IMAGE"
if [ $? -ne 0 ]; then
    echo
    echo "ERROR: It looks like you don't have graphviz. Please try 'brew install graphviz', or use the online service http://sandbox.kidstrythisathome.com/erdos/"
    exit 1
fi
open "$IMAGE"
