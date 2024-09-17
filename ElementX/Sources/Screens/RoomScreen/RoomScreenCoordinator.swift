//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import HTMLParser
import SwiftUI
import WysiwygComposer

struct RoomScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    var focussedEvent: FocusEvent?
    let timelineController: RoomTimelineControllerProtocol
    let mediaProvider: MediaProviderProtocol
    let mediaPlayerProvider: MediaPlayerProviderProtocol
    let voiceMessageMediaManager: VoiceMessageMediaManagerProtocol
    let emojiProvider: EmojiProviderProtocol
    let completionSuggestionService: CompletionSuggestionServiceProtocol
    let ongoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never>
    let appMediator: AppMediatorProtocol
    let appSettings: AppSettings
    let composerDraftService: ComposerDraftServiceProtocol
}

enum RoomScreenCoordinatorAction {
    case presentReportContent(itemID: TimelineItemIdentifier, senderID: String)
    case presentMediaUploadPicker(MediaPickerScreenSource)
    case presentMediaUploadPreviewScreen(URL)
    case presentRoomDetails
    case presentLocationPicker
    case presentPollForm(mode: PollFormMode)
    case presentLocationViewer(body: String, geoURI: GeoURI, description: String?)
    case presentEmojiPicker(itemID: TimelineItemIdentifier, selectedEmojis: Set<String>)
    case presentRoomMemberDetails(userID: String)
    case presentMessageForwarding(forwardingItem: MessageForwardingItem)
    case presentCallScreen
    case presentPinnedEventsTimeline
    case presentResolveSendFailure(failure: TimelineItemSendFailure.VerifiedUser, itemID: TimelineItemIdentifier)
}

final class RoomScreenCoordinator: CoordinatorProtocol {
    private var roomViewModel: RoomScreenViewModelProtocol
    private var timelineViewModel: TimelineViewModelProtocol
    private var composerViewModel: ComposerToolbarViewModelProtocol
    private var wysiwygViewModel: WysiwygComposerViewModel

    private var cancellables = Set<AnyCancellable>()

    private let actionsSubject: PassthroughSubject<RoomScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<RoomScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomScreenCoordinatorParameters) {
        var selectedPinnedEventID: String?
        if let focussedEvent = parameters.focussedEvent {
            selectedPinnedEventID = focussedEvent.shouldSetPin ? focussedEvent.eventID : nil
        }
        
        roomViewModel = RoomScreenViewModel(roomProxy: parameters.roomProxy,
                                            initialSelectedPinnedEventID: selectedPinnedEventID,
                                            mediaProvider: parameters.mediaProvider,
                                            ongoingCallRoomIDPublisher: parameters.ongoingCallRoomIDPublisher,
                                            appMediator: parameters.appMediator,
                                            appSettings: ServiceLocator.shared.settings,
                                            analyticsService: ServiceLocator.shared.analytics)
        
        timelineViewModel = TimelineViewModel(roomProxy: parameters.roomProxy,
                                              focussedEventID: parameters.focussedEvent?.eventID,
                                              timelineController: parameters.timelineController,
                                              mediaProvider: parameters.mediaProvider,
                                              mediaPlayerProvider: parameters.mediaPlayerProvider,
                                              voiceMessageMediaManager: parameters.voiceMessageMediaManager,
                                              userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                              appMediator: parameters.appMediator,
                                              appSettings: parameters.appSettings,
                                              analyticsService: ServiceLocator.shared.analytics)

        wysiwygViewModel = WysiwygComposerViewModel(minHeight: ComposerConstant.minHeight,
                                                    maxCompressedHeight: ComposerConstant.maxHeight,
                                                    maxExpandedHeight: ComposerConstant.maxHeight,
                                                    parserStyle: .elementX)
        let composerViewModel = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel,
                                                         completionSuggestionService: parameters.completionSuggestionService,
                                                         mediaProvider: parameters.mediaProvider,
                                                         mentionDisplayHelper: ComposerMentionDisplayHelper(timelineContext: timelineViewModel.context),
                                                         analyticsService: ServiceLocator.shared.analytics,
                                                         composerDraftService: parameters.composerDraftService)
        self.composerViewModel = composerViewModel
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification).sink { _ in
            composerViewModel.saveDraft()
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    func start() {
        timelineViewModel.actions
            .sink { [weak self] action in
                guard let self else { return }

                switch action {
                case .displayEmojiPicker(let itemID, let selectedEmojis):
                    actionsSubject.send(.presentEmojiPicker(itemID: itemID, selectedEmojis: selectedEmojis))
                case .displayReportContent(let itemID, let senderID):
                    actionsSubject.send(.presentReportContent(itemID: itemID, senderID: senderID))
                case .displayCameraPicker:
                    actionsSubject.send(.presentMediaUploadPicker(.camera))
                case .displayMediaPicker:
                    actionsSubject.send(.presentMediaUploadPicker(.photoLibrary))
                case .displayDocumentPicker:
                    actionsSubject.send(.presentMediaUploadPicker(.documents))
                case .displayLocationPicker:
                    actionsSubject.send(.presentLocationPicker)
                case .displayPollForm(let mode):
                    actionsSubject.send(.presentPollForm(mode: mode))
                case .displayMediaUploadPreviewScreen(let url):
                    actionsSubject.send(.presentMediaUploadPreviewScreen(url))
                case .tappedOnSenderDetails(userID: let userID):
                    actionsSubject.send(.presentRoomMemberDetails(userID: userID))
                case .displayMessageForwarding(let forwardingItem):
                    actionsSubject.send(.presentMessageForwarding(forwardingItem: forwardingItem))
                case .displayLocation(let body, let geoURI, let description):
                    actionsSubject.send(.presentLocationViewer(body: body, geoURI: geoURI, description: description))
                case .displayResolveSendFailure(let failure, let itemID):
                    actionsSubject.send(.presentResolveSendFailure(failure: failure, itemID: itemID))
                case .composer(let action):
                    composerViewModel.process(timelineAction: action)
                case .hasScrolled(direction: let direction):
                    roomViewModel.timelineHasScrolled(direction: direction)
                case .viewInRoomTimeline:
                    fatalError("The action: \(action) should not be sent to this coordinator")
                }
            }
            .store(in: &cancellables)

        composerViewModel.actions
            .sink { [weak self] action in
                guard let self else { return }

                timelineViewModel.process(composerAction: action)
            }
            .store(in: &cancellables)
        
        roomViewModel.actions
            .sink { [weak self] actions in
                guard let self else { return }
                
                switch actions {
                case .focusEvent(eventID: let eventID):
                    focusOnEvent(FocusEvent(eventID: eventID, shouldSetPin: false))
                case .displayPinnedEventsTimeline:
                    actionsSubject.send(.presentPinnedEventsTimeline)
                case .displayRoomDetails:
                    actionsSubject.send(.presentRoomDetails)
                case .displayCall:
                    actionsSubject.send(.presentCallScreen)
                case .removeComposerFocus:
                    composerViewModel.process(timelineAction: .removeFocus)
                }
            }
            .store(in: &cancellables)
        
        // Loading the draft requires the subscriptions to be set up first otherwise the room won't be be able to propagate the information to the composer.
        composerViewModel.loadDraft()
    }
    
    func focusOnEvent(_ focussedEvent: FocusEvent) {
        let eventID = focussedEvent.eventID
        if focussedEvent.shouldSetPin {
            roomViewModel.setSelectedPinnedEventID(eventID)
        }
        Task { await timelineViewModel.focusOnEvent(eventID: eventID) }
    }
    
    func stop() {
        composerViewModel.saveDraft()
        timelineViewModel.stop()
    }
    
    func toPresentable() -> AnyView {
        let composerToolbar = ComposerToolbar(context: composerViewModel.context,
                                              wysiwygViewModel: wysiwygViewModel,
                                              keyCommands: composerViewModel.keyCommands)

        return AnyView(RoomScreen(roomViewModel: roomViewModel,
                                  timelineViewModel: timelineViewModel,
                                  composerToolbar: composerToolbar)
                .onDisappear { [weak self] in
                    self?.composerViewModel.saveDraft()
                })
    }
}

enum ComposerConstant {
    static let minHeight: CGFloat = 22
    static let maxHeight: CGFloat = 250
    static let allowedHeightRange = minHeight...maxHeight
    static let translationThreshold: CGFloat = 60
}

private extension HTMLParserStyle {
    static let elementX = HTMLParserStyle(textColor: UIColor.label,
                                          linkColor: UIColor.link,
                                          codeBlockStyle: BlockStyle(backgroundColor: UIColor(.compound._bgCodeBlock),
                                                                     borderColor: UIColor(.compound.borderInteractiveSecondary),
                                                                     borderWidth: 1.0,
                                                                     cornerRadius: 2.0,
                                                                     padding: BlockStyle.Padding(horizontal: 10, vertical: 12),
                                                                     type: .background),
                                          quoteBlockStyle: BlockStyle(backgroundColor: UIColor(.compound.iconTertiary),
                                                                      borderColor: UIColor(.compound.borderInteractiveSecondary),
                                                                      borderWidth: 0.0,
                                                                      cornerRadius: 0.0,
                                                                      padding: BlockStyle.Padding(horizontal: 25, vertical: 12),
                                                                      type: .side(offset: 5, width: 4)))
}
