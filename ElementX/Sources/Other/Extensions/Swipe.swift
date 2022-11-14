//
// Copyright 2022 New Vector Ltd
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
import SwiftUI

extension View {
    func onSwipeGesture(minimumDistance: CGFloat,
                        up: @escaping (() -> Void) = { },
                        down: @escaping (() -> Void) = { },
                        left: @escaping (() -> Void) = { },
                        right: @escaping (() -> Void) = { }) -> some View {
        gesture(DragGesture(minimumDistance: minimumDistance, coordinateSpace: .local)
            .onEnded { value in
                if value.translation.width < 0 { left() }
                if value.translation.width > 0 { right() }
                if value.translation.height < 0 { up() }
                if value.translation.height > 0 { down() }
            })
    }
}
