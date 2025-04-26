//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

class VoiceMessageRoomTimelineItem: EventBasedMessageTimelineItemProtocol, Equatable, ObservableObject {
    let id: TimelineItemIdentifier
    let timestamp: String
    let isOutgoing: Bool
    let isEditable: Bool
    let canBeRepliedTo: Bool
    let isThreaded: Bool
    let sender: TimelineItemSender
    
    @Published var content: AudioRoomTimelineItemContent
    
    var replyDetails: TimelineItemReplyDetails?

    var properties = RoomTimelineItemProperties()
    
    private var cancellables = Set<AnyCancellable>()
    
    var body: String {
        content.caption ?? content.filename
    }
    
    var contentType: EventBasedMessageTimelineItemContentType {
        .voice(content)
    }
    
    init(id: TimelineItemIdentifier,
         timestamp: String,
         isOutgoing: Bool,
         isEditable: Bool,
         canBeRepliedTo: Bool,
         isThreaded: Bool,
         sender: TimelineItemSender,
         content: AudioRoomTimelineItemContent,
         replyDetails: TimelineItemReplyDetails? = nil,
         properties: RoomTimelineItemProperties = RoomTimelineItemProperties()) {
        self.id = id
        self.timestamp = timestamp
        self.isOutgoing = isOutgoing
        self.isEditable = isEditable
        self.canBeRepliedTo = canBeRepliedTo
        self.isThreaded = isThreaded
        self.sender = sender
        self.content = content
        self.replyDetails = replyDetails
        self.properties = properties
        
        // Log the initialization of the voice message timeline item
        MXLog.debug("VoiceMessageRoomTimelineItem: Initialized with ID: \(id), eventID: \(id.eventID ?? "nil")")
        
        // Observe transcriptions from the TranscriptionManager
        MXLog.debug("VoiceMessageRoomTimelineItem: About to call observeTranscriptions()")
        observeTranscriptions()
    }
    
    private func observeTranscriptions() {
        MXLog.debug("VoiceMessageRoomTimelineItem: observeTranscriptions() called")
        
        // Check if the TranscriptionManager is available
        if let transcriptionManager = ServiceLocator.shared.transcriptionManager {
            MXLog.debug("VoiceMessageRoomTimelineItem: TranscriptionManager is available, subscribing to transcriptionsPublisher")
            setupTranscriptionObserver(transcriptionManager)
        } else {
            MXLog.warning("VoiceMessageRoomTimelineItem: TranscriptionManager not available, will try again later")
            
            // Set up a timer to check for the TranscriptionManager periodically
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                MXLog.debug("VoiceMessageRoomTimelineItem: Checking for TranscriptionManager again")
                self.observeTranscriptions()
            }
        }
    }
    
    private func setupTranscriptionObserver(_ transcriptionManager: TranscriptionManagerProtocol) {
        MXLog.debug("VoiceMessageRoomTimelineItem: Setting up transcription observer")
        
        transcriptionManager.transcriptionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transcriptions in
                guard let self = self else { return }
                
                // Check if there's a transcription for this voice message
                if let eventID = self.id.eventID {
                    MXLog.debug("VoiceMessageRoomTimelineItem: Checking for transcription for voice message event ID: \(eventID)")
                    
                    // Log all available transcriptions for debugging
                    MXLog.debug("VoiceMessageRoomTimelineItem: Available transcriptions: \(transcriptions.count)")
                    for (key, transcription) in transcriptions {
                        MXLog.debug("VoiceMessageRoomTimelineItem: Transcription key: \(key), referencedEventId: \(transcription.referencedEventId), transcript: \(transcription.transcript)")
                    }
                    
                    // Iterate through all transcriptions and check if any of them reference this voice message event ID
                    var found = false
                    for (_, transcription) in transcriptions {
                        MXLog.debug("VoiceMessageRoomTimelineItem: Checking if transcription.referencedEventId: \(transcription.referencedEventId) matches voice message event ID: \(eventID)")
                        
                        if transcription.referencedEventId == eventID {
                            // Update the content with the transcription
                            var updatedContent = self.content
                            updatedContent.transcription = transcription.transcript
                            self.content = updatedContent
                            
                            MXLog.debug("VoiceMessageRoomTimelineItem: MATCH FOUND! Updated voice message with transcription: \(eventID)")
                            found = true
                            break
                        }
                    }
                    
                    if !found {
                        MXLog.debug("VoiceMessageRoomTimelineItem: No matching transcription found for voice message event ID: \(eventID)")
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // Required for Equatable conformance
    static func == (lhs: VoiceMessageRoomTimelineItem, rhs: VoiceMessageRoomTimelineItem) -> Bool {
        lhs.id == rhs.id &&
            lhs.timestamp == rhs.timestamp &&
            lhs.isOutgoing == rhs.isOutgoing &&
            lhs.isEditable == rhs.isEditable &&
            lhs.canBeRepliedTo == rhs.canBeRepliedTo &&
            lhs.isThreaded == rhs.isThreaded &&
            lhs.sender == rhs.sender &&
            lhs.content == rhs.content &&
            lhs.replyDetails == rhs.replyDetails &&
            lhs.properties == rhs.properties
    }
}
