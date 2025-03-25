# Forking

### Update the bundle identifier / app display name

To change the bundle identifier and the app display name for your app, open the `project.yml` file in the project root folder and change these settings:

```
BASE_BUNDLE_IDENTIFIER: io.element.elementx
APP_DISPLAY_NAME: Element X
```

After the changes run `xcodegen` to propagate them.

### Setup the location sharing

The location sharing feature on Element X is currently integrated with [MapLibre](https://maplibre.org).

The MapLibre SDK requires an API key to work, so you need to get one for yourself. 

After you get an API key, you need to configure the project by exporting it and regenerating the `Secrets.swift` file:

```
export MAPLIBRE_API_KEY=your_map_libre_key
bundle exec fastlane config_secrets
```

It’s not recommended to push your API key in your repository since other people may get it. 

One way to avoid pushing the API key by mistake is running on your machine the command: 
```
git update-index assume-unchanged Secrets/Secrets.swift
``` 
this will prevent pushing any update of the file `Secrets.swift`.

Finally you need to setup your map styles overriding the values you find in AppSettings.swift:

```swift
MapTilerConfiguration(baseURL: "https://api.maptiler.com/maps",
                      apiKey: Secrets.mapLibreAPIKey,
                      lightStyleID: "your_style_id_light",
                      darkStyleID: "your_style_id_dark")
```

You aren’t required to use custom styles here. You can use already available styles like `basic-v2` and `basic-v2-dark`