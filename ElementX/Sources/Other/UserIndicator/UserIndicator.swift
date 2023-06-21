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

enum UserIndicatorType: Equatable {
    case toast(progress: UserIndicator.Progress?)
    case modal(progress: UserIndicator.Progress?, interactiveDismissDisabled: Bool)
    
    static var toast: Self { .toast(progress: .none) }
    static var modal: Self { .modal(progress: .indeterminate, interactiveDismissDisabled: false) }
}

struct UserIndicator: Equatable, Identifiable {
    enum Progress: Equatable {
        static func == (lhs: UserIndicator.Progress, rhs: UserIndicator.Progress) -> Bool {
            switch (lhs, rhs) {
            case (.indeterminate, .indeterminate): return true
            case (.published(let lhsPublisher), .published(let rhsPublisher)): return lhsPublisher.value == rhsPublisher.value
            default: return false
            }
        }
        
        case indeterminate
        case published(CurrentValuePublisher<Double, Never>)
    }
    
    var id: String = UUID().uuidString
    var type: UserIndicatorType = .toast
    var title: String
    var iconName: String?
    var persistent = false
    
    // MARK: - Associated values from the type
    
    var progress: Progress? {
        switch type {
        case .toast(let progress): return progress
        case .modal(let progress, _): return progress
        }
    }
    
    var progressPublisher: CurrentValuePublisher<Double, Never> {
        switch type {
        case .toast(let progress), .modal(let progress, _):
            switch progress {
            case .none, .indeterminate:
                return CurrentValueSubject<Double, Never>(0.0).asCurrentValuePublisher()
            case .some(.published(let publisher)):
                return publisher
            }
        }
    }
    
    var interactiveDismissDisabled: Bool {
        switch type {
        case .toast:
            return false
        case .modal(_, let interactiveDismissDisabled):
            return interactiveDismissDisabled
        }
    }
}
