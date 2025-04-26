//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

/// Implementation of the TranscriptionManager protocol
class TranscriptionManager: TranscriptionManagerProtocol {
    /// Dictionary mapping audio event IDs to their transcriptions
    private var transcriptions: [String: TranscriptionData] = [:]
    
    /// Subject for publishing transcription updates
    private let transcriptionsSubject = CurrentValueSubject<[String: TranscriptionData], Never>([:])
    
    /// Publisher for transcription updates
    var transcriptionsPublisher: AnyPublisher<[String: TranscriptionData], Never> {
        transcriptionsSubject.eraseToAnyPublisher()
    }
    
    /// Add a new transcription to the manager
    /// - Parameter transcription: The transcription data to add
    func addTranscription(_ transcription: TranscriptionData) {
        MXLog.debug("Adding transcription for audio event: \(transcription.referencedEventId)")
        transcriptions[transcription.referencedEventId] = transcription
        transcriptionsSubject.send(transcriptions)
    }
    
    /// Get a transcription for a specific audio event ID
    /// - Parameter eventId: The event ID of the audio message
    /// - Returns: The transcription data if available, nil otherwise
    func getTranscription(forAudioEventId eventId: String) -> TranscriptionData? {
        transcriptions[eventId]
    }
}
