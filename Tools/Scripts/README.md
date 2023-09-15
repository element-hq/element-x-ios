# Scripts

## Create screen templates
New screen flows are currently using the MVVM-Coordinator pattern. Run [Tools/Scripts/createScreen.sh](Tools/Scripts/createScreen.sh) to create a new screen and all its required dependencies.

Usage:
```
./createScreen.sh Folder MyScreenName
```

After that run `xcodegen` to regenerate the project.  

`createScreen.sh` script will create:

- `Folder` within the `/ElementX/Sources/Screens/`. Files inside will be named `MyScreenNameXxx`.
- `MyScreenNameScreenUITests.swift` within `UITests/Sources`
- `MyScreenNameViewModelTests.swift` within `UnitTests/Sources/Unit`

