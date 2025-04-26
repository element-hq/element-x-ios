//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

// Define the necessary types here to avoid circular dependencies
/// Data structure to hold transcription information for voice messages
struct TranscriptionData {
    /// The event ID of the transcription event
    let eventId: String
    
    /// The event ID of the referenced audio message
    let referencedEventId: String
    
    /// The transcription text
    let transcript: String
    
    /// Timestamp when the transcription was created
    let timestamp: Date
    
    init(eventId: String, referencedEventId: String, transcript: String, timestamp: Date) {
        self.eventId = eventId
        self.referencedEventId = referencedEventId
        self.transcript = transcript
        self.timestamp = timestamp
    }
}

protocol TranscriptionManagerProtocol {
    /// Add a new transcription to the manager
    /// - Parameter transcription: The transcription data to add
    func addTranscription(_ transcription: TranscriptionData)
    
    /// Get a transcription for a specific audio event ID
    /// - Parameter eventId: The event ID of the audio message
    /// - Returns: The transcription data if available, nil otherwise
    func getTranscription(forAudioEventId eventId: String) -> TranscriptionData?
    
    /// Publisher for transcription updates
    var transcriptionsPublisher: AnyPublisher<[String: TranscriptionData], Never> { get }
}

class ServiceLocator {
    private(set) static var shared = ServiceLocator()
    
    private init() { }
    
    private(set) var userIndicatorController: UserIndicatorControllerProtocol!
    
    func register(userIndicatorController: UserIndicatorControllerProtocol) {
        self.userIndicatorController = userIndicatorController
    }
    
    private(set) var settings: AppSettings!
    
    func register(appSettings: AppSettings) {
        settings = appSettings
    }
    
    private(set) var analytics: AnalyticsService!
    
    func register(analytics: AnalyticsService) {
        self.analytics = analytics
    }
    
    private(set) var bugReportService: BugReportServiceProtocol!
    
    func register(bugReportService: BugReportServiceProtocol) {
        self.bugReportService = bugReportService
    }
    
    private(set) var transcriptionManager: TranscriptionManagerProtocol!
    
    func register(transcriptionManager: TranscriptionManagerProtocol) {
        MXLog.debug("ServiceLocator: Registering TranscriptionManager")
        self.transcriptionManager = transcriptionManager
        MXLog.debug("ServiceLocator: TranscriptionManager registered successfully")
    }
}
