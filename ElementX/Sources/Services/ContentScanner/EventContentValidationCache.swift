//
// Copyright 2026 Element Creations Ltd.
// Copyright 2026 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import Synchronization

final nonisolated class EventContentValidationCache: EventContentValidationCacheProtocol {
    private let subjects = Mutex<[String: CurrentValueSubject<ContentValidation, Never>]>([:])
    
    func validationPublisher(for eventID: String) -> CurrentValuePublisher<ContentValidation, Never> {
        subject(for: eventID).asCurrentValuePublisher()
    }
    
    func validation(for eventID: String) -> ContentValidation {
        subject(for: eventID).value
    }
    
    func update(_ validation: ContentValidation, for eventID: String) {
        subject(for: eventID).send(validation)
    }
    
    // MARK: - Private
    
    private func subject(for eventID: String) -> CurrentValueSubject<ContentValidation, Never> {
        subjects.withLock { subjects in
            if let subject = subjects[eventID] {
                return subject
            }
            
            let subject = CurrentValueSubject<ContentValidation, Never>(.unknown)
            subjects[eventID] = subject
            return subject
        }
    }
}
