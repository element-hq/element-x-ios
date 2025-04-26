//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

// Define the structure for parsing the JSON transcription
struct RefinedTranscriptionData: Codable {
    let refined_transcription: String
    let summary: String
    let topics: [Topic]
    
    struct Topic: Codable, Identifiable {
        let topic: String
        let responses: [String]
        
        var id: String { topic }
    }
}

struct VoiceMessageRoomTimelineView: View {
    @EnvironmentObject private var context: TimelineViewModel.Context
    @ObservedObject private var timelineItem: VoiceMessageRoomTimelineItem
    private let playerState: AudioPlayerState
    @State private var resumePlaybackAfterScrubbing = false
    
    // States for toggling between different views
    @State private var showTranscription = false
    @State private var showTopicsModal = false
    @State private var parsedData: RefinedTranscriptionData?
    
    init(timelineItem: VoiceMessageRoomTimelineItem, playerState: AudioPlayerState) {
        self.timelineItem = timelineItem
        self.playerState = playerState
        
        // Log that the view is being initialized
        MXLog.debug("VoiceMessageRoomTimelineView: Initialized with timelineItem ID: \(timelineItem.id), eventID: \(timelineItem.id.eventID ?? "nil")")
        MXLog.debug("VoiceMessageRoomTimelineView: Content has transcription: \(timelineItem.content.transcription != nil)")
    }
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    VoiceMessageRoomPlaybackView(playerState: playerState,
                                                 onPlayPause: onPlaybackPlayPause,
                                                 onSeek: { onPlaybackSeek($0) },
                                                 onScrubbing: { onPlaybackScrubbing($0) })
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 400)
                    
                    // Transcription toggle button
                    Button(action: {
                        withAnimation {
                            showTranscription.toggle()
                        }
                    }) {
                        Text("T")
                            .font(.system(size: 16, weight: .bold, design: .default))
                            .foregroundColor(showTranscription ? .white : .primary)
                            .frame(width: 25, height: 25)
                            .background(showTranscription ? Color.blue : Color.compound.bgSubtlePrimary)
                            .cornerRadius(8)
                    }
                    
                    // Summary/topics button
                    Button(action: {
                        showTopicsModal = true
                    }) {
                        Text("S")
                            .font(.system(size: 16, weight: .bold, design: .default))
                            .foregroundColor(.primary)
                            .frame(width: 25, height: 25)
                            .background(Color.compound.bgSubtlePrimary)
                            .cornerRadius(8)
                    }
                }
                
                // Display transcription content if available
                if let transcription = timelineItem.content.transcription, !transcription.isEmpty {
                    if parsedData == nil { }
                    
                    if let parsedData = parsedData {
                        Text(showTranscription ? parsedData.refined_transcription : parsedData.summary)
                            .font(.compound.bodyMD)
                            .foregroundColor(.compound.textPrimary)
                            .padding(8)
                            .background(Color.compound.bgSubtleSecondary)
                            .cornerRadius(8)
                            .onAppear {
                                MXLog.debug("VoiceMessageRoomTimelineView: Displaying transcription content")
                                if self.parsedData == nil {
                                    parseTranscription(transcription)
                                }
                            }
                            .transition(.opacity)
                    } else {
                        // Fallback to displaying raw transcription if parsing fails
                        Text(transcription)
                            .font(.compound.bodyMD)
                            .foregroundColor(.compound.textPrimary)
                            .padding(8)
                            .background(Color.compound.bgSubtleSecondary)
                            .cornerRadius(8)
                            .onAppear {
                                MXLog.debug("VoiceMessageRoomTimelineView: Displaying raw transcription: \(transcription)")
                                if parsedData == nil {
                                    parseTranscription(transcription)
                                }
                            }
                    }
                }
            }
            .sheet(isPresented: $showTopicsModal) {
                if let parsedData = parsedData {
                    TopicsModalView(topics: parsedData.topics)
                }
            }
        }
    }
    
    private func parseTranscription(_ transcription: String) {
        do {
            let decoder = JSONDecoder()
            if let jsonData = transcription.data(using: .utf8) {
                let data = try decoder.decode(RefinedTranscriptionData.self, from: jsonData)
                parsedData = data
                MXLog.debug("VoiceMessageRoomTimelineView: Successfully parsed transcription JSON")
            }
        } catch {
            MXLog.error("VoiceMessageRoomTimelineView: Failed to parse transcription JSON: \(error)")
        }
    }
    
    private func onPlaybackPlayPause() {
        context.send(viewAction: .handleAudioPlayerAction(.playPause(itemID: timelineItem.id)))
    }
    
    private func onPlaybackSeek(_ progress: Double) {
        context.send(viewAction: .handleAudioPlayerAction(.seek(itemID: timelineItem.id, progress: progress)))
    }
    
    private func onPlaybackScrubbing(_ dragging: Bool) {
        if dragging {
            if playerState.playbackState == .playing {
                resumePlaybackAfterScrubbing = true
                context.send(viewAction: .handleAudioPlayerAction(.playPause(itemID: timelineItem.id)))
            }
        } else if resumePlaybackAfterScrubbing {
            resumePlaybackAfterScrubbing = false
            context.send(viewAction: .handleAudioPlayerAction(.playPause(itemID: timelineItem.id)))
        }
    }
}

// Modal view for displaying topics and responses
struct TopicsModalView: View {
    let topics: [RefinedTranscriptionData.Topic]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(topics) { topic in
                    Section(header: Text(topic.topic).font(.headline)) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(topic.responses, id: \.self) { response in
                                Button(action: {
                                    // Copy response to clipboard
                                    UIPasteboard.general.string = response
                                }) {
                                    Text(response)
                                        .padding(8)
                                        .background(Color.compound.bgSubtlePrimary)
                                        .cornerRadius(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Topics & Responses")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct VoiceMessageRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    static let timelineItemIdentifier = TimelineItemIdentifier.randomEvent
    static let voiceRoomTimelineItem = VoiceMessageRoomTimelineItem(id: timelineItemIdentifier,
                                                                    timestamp: "Now",
                                                                    isOutgoing: false,
                                                                    isEditable: false,
                                                                    canBeRepliedTo: true,
                                                                    isThreaded: false,
                                                                    sender: .init(id: "Bob"),
                                                                    content: .init(filename: "audio.ogg",
                                                                                   duration: 300,
                                                                                   waveform: EstimatedWaveform.mockWaveform,
                                                                                   source: nil,
                                                                                   contentType: nil))
    
    static let playerState = AudioPlayerState(id: .timelineItemIdentifier(timelineItemIdentifier),
                                              title: L10n.commonVoiceMessage,
                                              duration: 10.0,
                                              waveform: EstimatedWaveform.mockWaveform,
                                              progress: 0.4)
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
            .previewDisplayName("Bubble")
    }
    
    static var body: some View {
        VoiceMessageRoomTimelineView(timelineItem: voiceRoomTimelineItem, playerState: playerState)
            .fixedSize(horizontal: false, vertical: true)
    }
}
