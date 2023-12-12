//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

/// The style for a map.
/// Values should be Map Libre style IDs generated with an account where the API key belongs to.
/// For more information read [FORKING.md](https://github.com/element-hq/element-x-ios/blob/develop/docs/FORKING.md#setup-the-location-sharing).
enum MapTilerStyle: String {
    case light = "9bc819c8-e627-474a-a348-ec144fe3d810"
    case dark = "dea61faf-292b-4774-9660-58fcef89a7f3"
}
