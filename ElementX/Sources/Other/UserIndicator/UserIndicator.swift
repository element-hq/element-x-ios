//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

enum UserIndicatorType: Equatable {
    case toast(progress: UserIndicator.Progress?)
    case modal(progress: UserIndicator.Progress?, interactiveDismissDisabled: Bool, allowsInteraction: Bool)
    
    static var toast: Self { .toast(progress: .none) }
    static var modal: Self { .modal(progress: .indeterminate, interactiveDismissDisabled: false, allowsInteraction: false) }
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
        case .modal(let progress, _, _): return progress
        }
    }
    
    var progressPublisher: CurrentValuePublisher<Double, Never> {
        switch type {
        case .toast(let progress), .modal(let progress, _, _):
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
        case .modal(_, let interactiveDismissDisabled, _):
            return interactiveDismissDisabled
        }
    }
    
    var allowsInteraction: Bool {
        switch type {
        case .toast:
            return true
        case .modal(_, _, let allowsInteraction):
            return allowsInteraction
        }
    }
}
