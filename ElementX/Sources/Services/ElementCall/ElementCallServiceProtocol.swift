//
// Copyright 2024 New Vector Ltd
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

enum ElementCallServiceAction {
    case startCall(roomID: String)
    case endCall(roomID: String)
}

enum ElementCallServiceNotificationKey: String {
    case roomID
    case roomDisplayName
}

let ElementCallServiceNotificationDiscardDelta = 10.0

// sourcery: AutoMockable
protocol ElementCallServiceProtocol {
    var actions: AnyPublisher<ElementCallServiceAction, Never> { get }
    
    func setupCallSession(roomID: String, roomDisplayName: String) async
    
    func tearDownCallSession()
}
