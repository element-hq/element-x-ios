#!/bin/bash
set -e

if which attranslate >/dev/null;
then
	echo -e "attranslate installed.\n"
else
	echo -e "warning: attranslate not installed, download with 'npm install --global attranslate'\n"
	exit -1
fi

./fetch_android_strings.sh

# Run "npm install --global attranslate" before you run this script.

XML_TO_STRINGS=( "--srcFormat=xml" "--targetFormat=ios-strings" "--service=sync-without-translate" )
ANDROID_RES_FOLDER="element-android/vector/src/main/res"

cd $ANDROID_RES_FOLDER

# Loop through Android string values
for d in values* ; do
	LANG_CODE="${d#*-}"
	if [ $LANG_CODE == "values" ]
	then
		# define base language
		LANG_CODE="en"
		XML_FILE="values/strings.xml"
	else
		XML_FILE="values-$LANG_CODE/strings.xml"
	fi

	# attranslate fails if no string found in the xml file, check the file contains any string
	if grep -Fq "</string>" $XML_FILE
	then
		echo -e "---------------------- Start converting $LANG_CODE ----------------------"
		FOLDER="../../../../../../../ElementX/Assets/Localizations/$LANG_CODE.lproj"
		mkdir -p $FOLDER
		STRINGS_FILE="$FOLDER/Localizable.strings"
		rm -rf $STRINGS_FILE
		attranslate "${XML_TO_STRINGS[@]}" --srcFile=$XML_FILE --targetFile=$STRINGS_FILE --srcLng=$LANG_CODE --targetLng=$LANG_CODE
		sed -i '' 's/""/"/g' $STRINGS_FILE
		sed -i '' 's/\\";/\\"";/g' $STRINGS_FILE
		sed -i '' 's/%s/%@/g' $STRINGS_FILE
		sed -i '' 's/$s/$@/g' $STRINGS_FILE
		sed -i '' 's/= ";/= "";/g' $STRINGS_FILE
		sed -i '' 's/"\.";/\.";/g' $STRINGS_FILE
		sed -i '' 's/"bot"/\\"bot\\""/g' $STRINGS_FILE
		sed -i '' 's/\${app_name}/%@/g' $STRINGS_FILE
		sed -i '' 's/\$ {app_name}/%@/g' $STRINGS_FILE
		# delete empty lines
		sed -i '' '/^$/d' $STRINGS_FILE
		# delete not translated lines
		sed -i '' '/"";/d' $STRINGS_FILE
		# lint the strings file
		plutil -lint $STRINGS_FILE
		echo -e "---------------------- Finish converting $LANG_CODE ----------------------\n"
	fi
done
