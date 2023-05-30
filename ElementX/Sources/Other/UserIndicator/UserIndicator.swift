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

enum UserIndicatorType {
    case toast
    case modal
}

struct UserIndicator: Equatable, Identifiable {
    static func == (lhs: UserIndicator, rhs: UserIndicator) -> Bool {
        lhs.id == rhs.id &&
            lhs.type == rhs.type &&
            lhs.title == rhs.title &&
            lhs.iconName == rhs.iconName &&
            lhs.persistent == rhs.persistent
    }

    enum LoaderType {
        case unknownProgress
        case progress(ProgressPublisher)
    }
    
    var id: String = UUID().uuidString
    var type = UserIndicatorType.toast
    var title: String
    var iconName: String?
    var persistent = false
    var loaderType: LoaderType? = .unknownProgress
    
    var progressPublisher: AnyPublisher<Double, Never> {
        switch loaderType {
        case .none, .unknownProgress:
            return Empty().eraseToAnyPublisher()
        case .some(.progress(let progress)):
            return progress.publisher.eraseToAnyPublisher()
        }
    }
}
