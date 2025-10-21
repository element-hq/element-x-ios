//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum LabsScreenViewAction {
    case clearCache
}

enum LabsScreenViewModelAction {
    case clearCache
}

struct LabsScreenViewState: BindableState {
    var bindings: LabsScreenViewStateBindings
}

// periphery: ignore - subscripts are seen as false positive
@dynamicMemberLookup
struct LabsScreenViewStateBindings {
    private let labsOptions: LabsOptionsProtocol

    init(labsOptions: LabsOptionsProtocol) {
        self.labsOptions = labsOptions
    }

    subscript<Setting>(dynamicMember keyPath: ReferenceWritableKeyPath<LabsOptionsProtocol, Setting>) -> Setting {
        get { labsOptions[keyPath: keyPath] }
        set { labsOptions[keyPath: keyPath] = newValue }
    }
}

protocol LabsOptionsProtocol: AnyObject {
    var threadsEnabled: Bool { get set }
}

extension AppSettings: LabsOptionsProtocol { }
