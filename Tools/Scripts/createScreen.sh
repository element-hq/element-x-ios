#!/bin/bash

GREEN='\033[0;32m'
NOCOLOR='\033[0m'

if [ ! $# -eq 1 ]; then
    echo -e "Usage: ${GREEN}./createScreen.sh Name${NOCOLOR}"
    echo -e "For example ${GREEN}./createScreen.sh Home${NOCOLOR} will create ${GREEN}HomeScreen${NOCOLOR}"
    exit 1
fi

SCREENS_DIR="../../ElementX/Sources/Screens"/$1Screen
UNIT_TESTS_DIR="../../UnitTests/Sources"

if [ -e $SCREENS_DIR ]; then
    echo "Error: Folder ${SCREENS_DIR} already exists"
    exit 1
fi

echo "Creating ${SCREENS_DIR}"

mkdir -p $SCREENS_DIR

echo "Copying screen files"

cp -R "Templates/SimpleScreenExample/ElementX/" $SCREENS_DIR/

echo "Copying tests"

cp -R "Templates/SimpleScreenExample/Tests/Unit/" $UNIT_TESTS_DIR/

SCREEN_NAME=$1
SCREEN_VAR_NAME=`echo $SCREEN_NAME | awk '{ print tolower(substr($0, 1, 1)) substr($0, 2) }'`

function rename_files {
    for file in $(find * -type f -print)
    do
      perl -p -i -e "s/Template/"$SCREEN_NAME"/g" $file
      perl -p -i -e "s/template/"$SCREEN_VAR_NAME"/g" $file

      mv ${file} ${file/Template/$SCREEN_NAME}
    done
}

echo "Renaming files"

cd $SCREENS_DIR
rename_files
cd - > /dev/null

cd $UI_TESTS_DIR
rename_files
cd - > /dev/null

cd $UNIT_TESTS_DIR
rename_files
cd - > /dev/null

echo "Done"
