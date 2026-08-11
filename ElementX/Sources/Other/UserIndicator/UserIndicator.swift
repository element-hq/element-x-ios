//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

enum UserIndicatorType: Equatable {
    case toast(progress: UserIndicator.Progress?)
    case modal(progress: UserIndicator.Progress?, interactiveDismissDisabled: Bool, allowsInteraction: Bool)
    
    static var toast: Self {
        .toast(progress: .none)
    }
    
    static var modal: Self {
        .modal(progress: .indeterminate, interactiveDismissDisabled: false, allowsInteraction: false)
    }
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
    var message: String?
    var icon: KeyPath<CompoundIcons, Image>?
    var persistent = false
    /// When set, a modal indicator's obscured background becomes tappable and
    /// a tap calls this instead of blocking, letting the user abandon whatever
    /// the indicator is waiting on.
    var onCancel: (() -> Void)?

    static func == (lhs: UserIndicator, rhs: UserIndicator) -> Bool {
        lhs.id == rhs.id
            && lhs.type == rhs.type
            && lhs.title == rhs.title
            && lhs.message == rhs.message
            && lhs.icon == rhs.icon
            && lhs.persistent == rhs.persistent
    }

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
