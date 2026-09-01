//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import Testing

@MainActor
struct TimelineInteractionHandlerTests {
    private static let firstSourceURL = URL("mxc://matrix.org/voice1")
    private static let secondSourceURL = URL("mxc://matrix.org/voice2")
    
    private let audioPlayer: AudioPlayerMock
    private let mediaPlayerProvider: MediaPlayerProviderMock
    private let actionsSubject: PassthroughSubject<AudioPlayerAction, Never>
    private let loadedSourceURLsSubject: PassthroughSubject<URL, Never>
    
    private static let firstVoiceMessage = makeVoiceMessage(id: "voice1", sourceURL: firstSourceURL)
    private static let secondVoiceMessage = makeVoiceMessage(id: "voice2", sourceURL: secondSourceURL)
    private static let textMessage = TextRoomTimelineItem(id: .event(uniqueID: .init("text"), eventOrTransactionID: .eventID("text")),
                                                          timestamp: .mock,
                                                          isOutgoing: false,
                                                          isEditable: false,
                                                          canBeRepliedTo: true,
                                                          sender: .init(id: "@sender:example.com"),
                                                          content: .init(body: "Test message"))
    
    init() {
        let player = AudioPlayerMock()
        let actionsSubject = PassthroughSubject<AudioPlayerAction, Never>()
        let loadedSourceURLsSubject = PassthroughSubject<URL, Never>()
        
        player.actions = actionsSubject.eraseToAnyPublisher()
        player.state = .stopped
        player.currentTime = 0
        player.duration = 10
        player.loadSourceURLPlaybackURLAutoplayClosure = { sourceURL, _, _ in
            player.sourceURL = sourceURL
            player.state = .playing
            loadedSourceURLsSubject.send(sourceURL)
        }
        player.playClosure = { player.state = .playing }
        player.pauseClosure = { player.state = .paused }
        player.stopClosure = { player.state = .stopped }
        
        let states = [Self.firstVoiceMessage, Self.secondVoiceMessage]
            .reduce(into: [TimelineItemIdentifier.UniqueID: AudioPlayerState]()) { states, item in
                states[item.id.uniqueID] = AudioPlayerState(id: .timelineItemIdentifier(item.id),
                                                            title: L10n.commonVoiceMessage,
                                                            duration: item.content.duration)
            }
        
        // Hands out one stable player state per voice message, as the real provider does.
        let mediaPlayerProvider = MediaPlayerProviderMock()
        mediaPlayerProvider.player = player
        mediaPlayerProvider.playerStateForClosure = { identifier in
            guard case .timelineItemIdentifier(let itemID) = identifier else { return nil }
            return states[itemID.uniqueID]
        }
        
        audioPlayer = player
        self.mediaPlayerProvider = mediaPlayerProvider
        self.actionsSubject = actionsSubject
        self.loadedSourceURLsSubject = loadedSourceURLsSubject
    }
    
    // MARK: - Voice message autoplay
    
    @Test
    func autoplaysTheFollowingVoiceMessage() async throws {
        let handler = makeHandler(timelineItems: [Self.firstVoiceMessage, Self.secondVoiceMessage])
        
        await handler.playPauseAudio(for: Self.firstVoiceMessage.id)
        #expect(loadedSourceURLs == [Self.firstSourceURL])
        
        let deferred = deferFulfillment(loadedSourceURLsSubject) { $0 == Self.secondSourceURL }
        actionsSubject.send(.didStartPlaying)
        actionsSubject.send(.didFinishPlaying)
        try await deferred.fulfill()
        
        #expect(loadedSourceURLs == [Self.firstSourceURL, Self.secondSourceURL])
        #expect(mediaPlayerProvider.playSoundEffectReceivedSoundEffect == .tink)
    }
    
    @Test
    func doesNotAutoplayAcrossAnotherMessage() async {
        let handler = makeHandler(timelineItems: [Self.firstVoiceMessage, Self.textMessage, Self.secondVoiceMessage])
        
        await handler.playPauseAudio(for: Self.firstVoiceMessage.id)
        actionsSubject.send(.didStartPlaying)
        actionsSubject.send(.didFinishPlaying)
        await allowPlayerActionsToBeHandled()
        
        #expect(loadedSourceURLs == [Self.firstSourceURL])
        #expect(!mediaPlayerProvider.playSoundEffectCalled)
    }
    
    @Test
    func doesNotAutoplayAfterTheLastVoiceMessage() async {
        let handler = makeHandler(timelineItems: [Self.firstVoiceMessage])
        
        await handler.playPauseAudio(for: Self.firstVoiceMessage.id)
        actionsSubject.send(.didStartPlaying)
        actionsSubject.send(.didFinishPlaying)
        await allowPlayerActionsToBeHandled()
        
        #expect(loadedSourceURLs == [Self.firstSourceURL])
        #expect(!mediaPlayerProvider.playSoundEffectCalled)
    }
    
    @Test
    func doesNotAutoplayAfterPausing() async {
        let handler = makeHandler(timelineItems: [Self.firstVoiceMessage, Self.secondVoiceMessage])
        
        await handler.playPauseAudio(for: Self.firstVoiceMessage.id)
        actionsSubject.send(.didStartPlaying)
        await allowPlayerActionsToBeHandled()
        
        await handler.playPauseAudio(for: Self.firstVoiceMessage.id)
        #expect(audioPlayer.pauseCalled)
        
        actionsSubject.send(.didFinishPlaying)
        await allowPlayerActionsToBeHandled()
        
        #expect(loadedSourceURLs == [Self.firstSourceURL])
    }
    
    @Test
    func replayingAVoiceMessageDoesNotJumpToTheFollowingOne() async throws {
        let handler = makeHandler(timelineItems: [Self.firstVoiceMessage, Self.secondVoiceMessage])
        
        // Play the first message all the way through so that the second one takes over.
        await handler.playPauseAudio(for: Self.firstVoiceMessage.id)
        let autoplay = deferFulfillment(loadedSourceURLsSubject) { $0 == Self.secondSourceURL }
        actionsSubject.send(.didStartPlaying)
        actionsSubject.send(.didFinishPlaying)
        try await autoplay.fulfill()
        actionsSubject.send(.didStartPlaying)
        await allowPlayerActionsToBeHandled()
        
        // Loading tears the player down, which is where the spurious end of playback came from.
        audioPlayer.loadSourceURLPlaybackURLAutoplayClosure = { [audioPlayer, actionsSubject, loadedSourceURLsSubject] sourceURL, _, _ in
            actionsSubject.send(.didFinishPlaying)
            audioPlayer.sourceURL = sourceURL
            audioPlayer.state = .playing
            loadedSourceURLsSubject.send(sourceURL)
        }
        
        let replay = deferFulfillment(loadedSourceURLsSubject) { $0 == Self.firstSourceURL }
        await handler.playPauseAudio(for: Self.firstVoiceMessage.id)
        try await replay.fulfill()
        await allowPlayerActionsToBeHandled()
        
        #expect(loadedSourceURLs == [Self.firstSourceURL, Self.secondSourceURL, Self.firstSourceURL])
    }
    
    // MARK: - Helpers
    
    private var loadedSourceURLs: [URL] {
        audioPlayer.loadSourceURLPlaybackURLAutoplayReceivedInvocations.map(\.sourceURL)
    }
    
    /// The handler reacts to the player's actions in detached tasks, this gives them a chance to run.
    private func allowPlayerActionsToBeHandled() async {
        for _ in 0..<10 {
            await Task.yield()
        }
    }
    
    private func makeHandler(timelineItems: [RoomTimelineItemProtocol]) -> TimelineInteractionHandler {
        let voiceMessageRecorder = VoiceMessageRecorderMock()
        voiceMessageRecorder.isRecording = false
        
        let voiceMessageMediaManager = VoiceMessageMediaManagerMock()
        voiceMessageMediaManager.loadVoiceMessageFromSourceBodyReturnValue = URL("file:///voice-message.m4a")
        
        let userSession = UserSessionMock(.init())
        userSession.voiceMessageMediaManager = voiceMessageMediaManager
        
        let appSettings = AppSettings.volatile()
        
        return TimelineInteractionHandler(roomProxy: JoinedRoomProxyMock(.init()),
                                          timelineController: TimelineControllerMock(.init(timelineItems: timelineItems)),
                                          userSession: userSession,
                                          mediaPlayerProvider: mediaPlayerProvider,
                                          voiceMessageRecorder: voiceMessageRecorder,
                                          userIndicatorController: UserIndicatorControllerMock(),
                                          appMediator: AppMediatorMock(.init()),
                                          appSettings: appSettings,
                                          analyticsService: AnalyticsServiceMock(.init()),
                                          emojiProvider: EmojiProvider(appSettings: appSettings),
                                          linkMetadataProvider: LinkMetadataProvider(),
                                          timelineControllerFactory: TimelineControllerFactoryMock(.init()))
    }
    
    private static func makeVoiceMessage(id: String, sourceURL: URL) -> VoiceMessageRoomTimelineItem {
        VoiceMessageRoomTimelineItem(id: .event(uniqueID: .init(id), eventOrTransactionID: .eventID(id)),
                                     timestamp: .mock,
                                     isOutgoing: false,
                                     isEditable: false,
                                     canBeRepliedTo: true,
                                     sender: .init(id: "@sender:example.com"),
                                     content: .init(filename: "audio.ogg",
                                                    duration: 10,
                                                    waveform: .mockWaveform,
                                                    source: try? MediaSourceProxy(url: sourceURL, mimeType: "audio/ogg"),
                                                    fileSize: nil,
                                                    contentType: nil))
    }
}
