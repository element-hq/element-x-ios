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
## Create screen templates
New screen flows are currently using MVVM-Coordinator pattern. Run [Tools/Scripts/createScreen.sh](Tools/Scripts/createScreen.sh) to create a new screen or a new screen flow.

Usage:
```
./createScreen.sh Folder MyScreenName
```

After that run `xcodegen` to regenerate the project.  

`createScreen.sh` script will create:

- `Folder` within the `/ElementX/Sources/Screens/`. Files inside will be named `MyScreenNameXxx`.
- `MyScreenNameScreenUITests.swift` within `UITests/Sources`
- `MyScreenNameViewModelTests.swift` within `UnitTests/Sources/Unit`

