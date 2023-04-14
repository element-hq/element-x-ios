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

import Foundation

import URLRouting

enum AppRoute {
    case room(roomID: String)
}

struct AppRouterManager {
    private let deeplinkRouter = OneOf {
        Route(.case(AppRoute.room(roomID:))) {
            // Check with product if this is the expect path
            Path { "room" }
            Query {
                Field("id") { Parse(.string) }
            }
        }
    }

    private let permalinkRouter = OneOf {
        Route(.case(AppRoute.room(roomID:))) {
            Host("matrix.to")
            Path {
                "#"
                Parse(.string)
            }
        }
    }

    func route(from url: URL) -> AppRoute? {
        var route: AppRoute?
        if let deeplinkRoute = try? deeplinkRouter.match(url: url) {
            route = deeplinkRoute
        } else if let permalinkRoute = try? permalinkRouter.match(url: url) {
            route = permalinkRoute
        }
        return route
    }
}
