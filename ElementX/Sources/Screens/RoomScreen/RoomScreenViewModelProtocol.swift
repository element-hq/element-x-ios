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

import Combine
import Foundation
import SwiftUI

@MainActor
protocol RoomScreenViewModelProtocol {
    var callback: ((RoomScreenViewModelAction) -> Void)? { get set }
    var context: RoomScreenViewModelType.Context { get }
}

protocol RoomScreenComposerActionHandler: AnyObject {
    var publisher: Published<ComposerToolbarViewState>.Publisher { get }
    func process(composerAction: RoomScreenComposerAction)
}

protocol RoomScreenComposerProvider {
    var handler: RoomScreenComposerActionHandler? { get }
    var view: AnyView { get }
}
