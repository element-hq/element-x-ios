# Scripts

## Iconizer
Generates all app icon variants from one single .pdf file.

Usage:
```
sh iconizer.sh ../ElementX/Supporting\ Files/AppIcon.pdf ../ElementX/Supporting\ Files
```

## Localizer
Generates all app localization files and imports them to the project, by downloading strings from [element-android](https://github.com/vector-im/element-android/tree/develop/vector/src/main/res) and converting them to `strings` and `stringsdict` files.

Usage:
```
./localizer.py
```

## Boot Test Simulator
Boots a desired simulator and makes status bar overrides on that.

Usage:
```
./bootTestSimulator.py 'iPhone 13 Pro Max'
```
