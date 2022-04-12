#!/bin/sh

#
# Iconizer shell script by Steve Richey (srichey@floatlearning.com)
# Modified by Rich Ellis (rich@richellis.net) based on contributions on Github from crishoj, giria
# https://gist.github.com/steverichey/8493f3bd31ae71a9c933/forks
#
# This is a simple tool to generate all necessary app icon sizes and the JSON file for an *EXISTING* Xcode project from one file.
# To use: specify the path to your vector graphic (PDF format) and the path to your Xcode folder containing Assets.xcassets
# Example: sh iconizer.sh MyVectorGraphic.pdf MyXcodeProject
#
# Requires ImageMagick: http://www.imagemagick.org/
# Requires GhostScript: http://www.ghostscript.com/
#
# Install dependencies with Homebrew: http://brew.sh/
#    brew install imagemagic
#    brew install ghostscript

# Exit on first error
set -e

if [ $# -ne 2 ]
  then
        echo "\nUsage: sh iconizer.sh file.pdf FolderName\n"
elif [ ! -e "$1" ]
    then
        echo "Did not find file $1, expected path to a vector image file.\n"
elif [ ${1: -4} != ".pdf" ]
    then
        echo "File $1 is not a vector image file! Expected PDF file.\n"
elif [ ! -d "./$2/Assets.xcassets/AppIcon.appiconset/" ]
    then
        echo "Did not find Xcode folder $2, expected folder which contains Assets.xcassets/AppIcon.appiconset/ \n"
elif [ ! -x "$(command -v convert)" ]
    then
        echo "Executable 'convert' not found in path. Please install ImageMagick."
elif [ ! -x "$(command -v gs)" ]
    then
        echo "Executable 'gs' not found in path. Please install GhostScript."
else
    echo "Creating icons from $1 into $2/Assets.xcassets/AppIcon.appiconset/..."

    for i in 16 20 29 32 40 50 57 58 60 64 72 76 80 87 100 114 120 128 144 152 167 180 256 512 1024
    do
        file_name="./$2/Assets.xcassets/AppIcon.appiconset/appicon_$i.png"
        if [ ! -e "$file_name" ]
        then
            echo "Creating $i px icon"
            convert -density 400 "$1" -scale $ix$i "$file_name"
        fi
    done

    echo "Created app icon files, writing Contents.json file..."

    echo '{"images":[

{\n"size":"1024x1024",\n"idiom":"ios-marketing",\n"filename":"appicon_1024.png",\n"scale":"1x"\n},



{\n"size":"20x20",\n"idiom":"iphone",\n"filename":"appicon_40.png",\n"scale":"2x"\n},
{\n"size":"20x20",\n"idiom":"iphone",\n"filename":"appicon_60.png",\n"scale":"3x"\n},

{\n"size":"29x29",\n"idiom":"iphone",\n"filename":"appicon_29.png",\n"scale":"1x"\n},
{\n"size":"29x29",\n"idiom":"iphone",\n"filename":"appicon_58.png",\n"scale":"2x"\n},
{\n"size":"29x29",\n"idiom":"iphone",\n"filename":"appicon_87.png",\n"scale":"3x"\n},

{\n"size":"40x40",\n"idiom":"iphone",\n"filename":"appicon_80.png",\n"scale":"2x"\n},
{\n"size":"40x40",\n"idiom":"iphone",\n"filename":"appicon_120.png",\n"scale":"3x"\n},

{\n"size":"57x57",\n"idiom":"iphone",\n"filename":"appicon_57.png",\n"scale":"1x"\n},
{\n"size":"57x57",\n"idiom":"iphone",\n"filename":"appicon_114.png",\n"scale":"2x"\n},

{\n"size":"60x60",\n"idiom":"iphone",\n"filename":"appicon_120.png",\n"scale":"2x"\n},
{\n"size":"60x60",\n"idiom":"iphone",\n"filename":"appicon_180.png",\n"scale":"3x"\n},



{\n"size":"20x20",\n"idiom":"ipad",\n"filename":"appicon_20.png",\n"scale":"1x"\n},
{\n"size":"20x20",\n"idiom":"ipad",\n"filename":"appicon_40.png",\n"scale":"2x"\n},

{\n"size":"29x29",\n"idiom":"ipad",\n"filename":"appicon_29.png",\n"scale":"1x"\n},
{\n"size":"29x29",\n"idiom":"ipad",\n"filename":"appicon_58.png",\n"scale":"2x"\n},

{\n"size":"40x40",\n"idiom":"ipad",\n"filename":"appicon_40.png",\n"scale":"1x"\n},
{\n"size":"40x40",\n"idiom":"ipad",\n"filename":"appicon_80.png",\n"scale":"2x"\n},

{\n"size":"50x50",\n"idiom":"ipad",\n"filename":"appicon_50.png",\n"scale":"1x"\n},
{\n"size":"50x50",\n"idiom":"ipad",\n"filename":"appicon_100.png",\n"scale":"2x"\n},

{\n"size":"72x72",\n"idiom":"ipad",\n"filename":"appicon_72.png",\n"scale":"1x"\n},
{\n"size":"72x72",\n"idiom":"ipad",\n"filename":"appicon_144.png",\n"scale":"2x"\n},

{\n"size":"76x76",\n"idiom":"ipad",\n"filename":"appicon_76.png",\n"scale":"1x"\n},
{\n"size":"76x76",\n"idiom":"ipad",\n"filename":"appicon_152.png",\n"scale":"2x"\n},

{\n"size":"83.5x83.5",\n"idiom":"ipad",\n"filename":"appicon_167.png",\n"scale":"2x"\n},




{\n"size":"60x60",\n"idiom":"car",\n"filename":"appicon_120.png",\n"scale":"2x"\n},
{\n"size":"60x60",\n"idiom":"car",\n"filename":"appicon_180.png",\n"scale":"3x"\n},




{\n"size":"16x16",\n"idiom":"mac",\n"filename":"appicon_16.png",\n"scale":"1x"\n},
{\n"size":"16x16",\n"idiom":"mac",\n"filename":"appicon_32.png",\n"scale":"2x"\n},

{\n"size":"32x32",\n"idiom":"mac",\n"filename":"appicon_32.png",\n"scale":"1x"\n},
{\n"size":"32x32",\n"idiom":"mac",\n"filename":"appicon_64.png",\n"scale":"2x"\n},

{\n"size":"128x128",\n"idiom":"mac",\n"filename":"appicon_128.png",\n"scale":"1x"\n},
{\n"size":"128x128",\n"idiom":"mac",\n"filename":"appicon_256.png",\n"scale":"2x"\n},

{\n"size":"256x256",\n"idiom":"mac",\n"filename":"appicon_256.png",\n"scale":"1x"\n},
{\n"size":"256x256",\n"idiom":"mac",\n"filename":"appicon_512.png",\n"scale":"2x"\n},

{\n"size":"512x512",\n"idiom":"mac",\n"filename":"appicon_512.png",\n"scale":"1x"\n},
{\n"size":"512x512",\n"idiom":"mac",\n"filename":"appicon_1024.png",\n"scale":"2x"\n}\n],



"info":{\n"version":1,\n"author":"xcode"\n}\n}' > "./$2/Assets.xcassets/AppIcon.appiconset/Contents.json"

    echo "Complete!"
fi
