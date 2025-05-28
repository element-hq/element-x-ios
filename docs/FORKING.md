# Forking

### Project Configuration

To create a fork, the first step is to update some of the project's configuration options such as the bundle identifier and the app's display name. To do this, open the `app.yml` file in the project root folder and at a minimum change these settings:

```
APP_DISPLAY_NAME: Element X
APP_GROUP_IDENTIFIER: group.io.element
BASE_BUNDLE_IDENTIFIER: io.element.elementx
DEVELOPMENT_TEAM: 7J4U792NQT
```

After making the changes, run `xcodegen` to regenerate the project.

### Runtime Configuration

Once your project is configured and compiles, you'll likely want to tweak how the app works. [AppSettings.swift](../ElementX/Sources/Application/AppSettings.swift) contains all of the settings used by the app at runtime.

### Authentication

Element X's primary authentication method is to use OIDC against [Matrix Authentication Service](https://github.com/element-hq/matrix-authentication-service) (MAS). Unlike the older password-based authentication flows, this requires a small amount of configuration within the app. You need to make sure that all of the values passed to the SDK in the [OIDCConfiguration](https://github.com/element-hq/element-x-ios/blob/b2a37ec9d39622586754f58a98dcda35e0e8cf7e/ElementX/Sources/Application/AppSettings.swift#L206-L212) are hosted on the same domain otherwise dynamic client registration will fail. As we're using an [HTTPS callback](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession/callback/https(host:path:)) for the web authentication, Apple validates ownership of the domain with the app. There are 2 steps to make sure this validation works:
- Add an [apple-app-site-association](https://developer.apple.com/documentation/xcode/supporting-associated-domains) file on your website with your app included in the `webcredentials` section.
- Update the [webcredentials](https://github.com/element-hq/element-x-ios/blob/b2a37ec9d39622586754f58a98dcda35e0e8cf7e/ElementX/SupportingFiles/target.yml#L122) associated domain entitlement in the app to match your domain and re-run `xcodegen`.

### Setup the location sharing

The location sharing feature on Element X is currently integrated with [MapLibre](https://maplibre.org).

The MapLibre SDK requires an API key to work, so you need to get one for yourself. 

After you get an API key, you need to configure the project by updating the `Secrets.swift`.

It’s not recommended to push your API key in your repository since other people may get it so the mechanism for updating this file is left up to the reader. 

An option would be to export it to your environment and use the existing `Secrets.pkl` file to update them like so:
`pkl eval -o Secrets.swift Secrets.pkl`

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