# Forking

### Location Sharing

The Location Sharing feature on Element X is currently integrated with [MapLibre](https://maplibre.org).

The MapLibre SDK requires an API key to work, so you need to get one for yourself. 

After you got an API key, you need to configure the project following one of these steps:

- Create a file named `.maplibre_key` in the project root directory. This file must contain the API key without spaces or newline characters. Then run `swift run tools setup-project` to generate the project.
- Paste your API key into the file `project.yml` as a value of the key `MAPLIBRE_API_KEY`. Then run `xcodegen` to generate the project.

It’s not recommended to push your API key in your repository, since other people may get it.
We recommend to use the first method to inject your API key, since the `.maplibre_key` is already inside the `.gitignore`. 
However be careful about not pushing the generated project or the `project.yml` with your API key inside. 
