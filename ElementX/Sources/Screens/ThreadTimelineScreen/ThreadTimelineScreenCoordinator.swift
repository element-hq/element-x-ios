//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import HTMLParser
import SwiftUI
import WysiwygComposer

struct ThreadTimelineScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let roomProxy: JoinedRoomProxyProtocol
    let focussedEventID: String?
    let timelineController: TimelineControllerProtocol
    let mediaPlayerProvider: MediaPlayerProviderProtocol
    let emojiProvider: EmojiProviderProtocol
    let linkMetadataProvider: LinkMetadataProviderProtocol
    let completionSuggestionService: CompletionSuggestionServiceProtocol
    let appMediator: AppMediatorProtocol
    let appSettings: AppSettings
    let analytics: AnalyticsService
    let composerDraftService: ComposerDraftServiceProtocol
    let timelineControllerFactory: TimelineControllerFactoryProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum ThreadTimelineScreenCoordinatorAction {
    case presentReportContent(itemID: TimelineItemIdentifier, senderID: String)
    case presentMediaUploadPicker(mode: MediaPickerScreenMode)
    case presentMediaUploadPreviewScreen(mediaURLs: [URL])
    case presentLocationPicker
    case presentLocationViewer(body: String, geoURI: GeoURI, description: String?)
    case presentPollForm(mode: PollFormMode)
    case presentEmojiPicker(itemID: TimelineItemIdentifier, selectedEmojis: Set<String>)
    case presentRoomMemberDetails(userID: String)
    case presentMessageForwarding(forwardingItem: MessageForwardingItem)
    case presentResolveSendFailure(failure: TimelineItemSendFailure.VerifiedUser, sendHandle: SendHandleProxy)
}

final class ThreadTimelineScreenCoordinator: CoordinatorProtocol {
    private let parameters: ThreadTimelineScreenCoordinatorParameters
    private let viewModel: ThreadTimelineScreenViewModelProtocol
    private let timelineViewModel: TimelineViewModelProtocol
    private var composerViewModel: ComposerToolbarViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<ThreadTimelineScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<ThreadTimelineScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: ThreadTimelineScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = ThreadTimelineScreenViewModel(roomProxy: parameters.roomProxy, userSession: parameters.userSession)
        
        timelineViewModel = TimelineViewModel(roomProxy: parameters.roomProxy,
                                              focussedEventID: parameters.focussedEventID,
                                              timelineController: parameters.timelineController,
                                              userSession: parameters.userSession,
                                              mediaPlayerProvider: parameters.mediaPlayerProvider,
                                              userIndicatorController: parameters.userIndicatorController,
                                              appMediator: parameters.appMediator,
                                              appSettings: parameters.appSettings,
                                              analyticsService: parameters.analytics,
                                              emojiProvider: parameters.emojiProvider,
                                              linkMetadataProvider: parameters.linkMetadataProvider,
                                              timelineControllerFactory: parameters.timelineControllerFactory)
        
        let wysiwygViewModel = WysiwygComposerViewModel(minHeight: ComposerConstant.minHeight,
                                                        maxCompressedHeight: ComposerConstant.maxHeight,
                                                        maxExpandedHeight: ComposerConstant.maxHeight,
                                                        parserStyle: .elementX)
        
        composerViewModel = ComposerToolbarViewModel(initialText: nil,
                                                     roomProxy: parameters.roomProxy,
                                                     wysiwygViewModel: wysiwygViewModel,
                                                     completionSuggestionService: parameters.completionSuggestionService,
                                                     mediaProvider: parameters.userSession.mediaProvider,
                                                     mentionDisplayHelper: ComposerMentionDisplayHelper(timelineContext: timelineViewModel.context),
                                                     appSettings: parameters.appSettings,
                                                     analyticsService: parameters.analytics,
                                                     composerDraftService: parameters.composerDraftService)
    }
    
    func start() {
        viewModel.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .displayMessageForwarding(let forwardingItem):
                    actionsSubject.send(.presentMessageForwarding(forwardingItem: forwardingItem))
                }
            }
            .store(in: &cancellables)
        
        timelineViewModel.actions
            .sink { [weak self] action in
                guard let self else { return }

                switch action {
                case .displayEmojiPicker(let itemID, let selectedEmojis):
                    actionsSubject.send(.presentEmojiPicker(itemID: itemID, selectedEmojis: selectedEmojis))
                case .displayReportContent(let itemID, let senderID):
                    actionsSubject.send(.presentReportContent(itemID: itemID, senderID: senderID))
                case .displayCameraPicker:
                    actionsSubject.send(.presentMediaUploadPicker(mode: .init(source: .camera, selectionType: .multiple)))
                case .displayMediaPicker:
                    actionsSubject.send(.presentMediaUploadPicker(mode: .init(source: .photoLibrary, selectionType: .multiple)))
                case .displayDocumentPicker:
                    actionsSubject.send(.presentMediaUploadPicker(mode: .init(source: .documents, selectionType: .multiple)))
                case .displayMediaPreview(let mediaPreviewViewModel):
                    viewModel.displayMediaPreview(mediaPreviewViewModel)
                case .displayLocationPicker:
                    actionsSubject.send(.presentLocationPicker)
                case .displayLocation(let body, let geoURI, let description):
                    actionsSubject.send(.presentLocationViewer(body: body,
                                                               geoURI: geoURI,
                                                               description: description))
                case .displayPollForm(let mode):
                    actionsSubject.send(.presentPollForm(mode: mode))
                case .displayMediaUploadPreviewScreen(let mediaURLs):
                    actionsSubject.send(.presentMediaUploadPreviewScreen(mediaURLs: mediaURLs))
                case .displaySenderDetails(userID: let userID):
                    actionsSubject.send(.presentRoomMemberDetails(userID: userID))
                case .displayMessageForwarding(let forwardingItem):
                    actionsSubject.send(.presentMessageForwarding(forwardingItem: forwardingItem))
                case .displayResolveSendFailure(let failure, let sendHandle):
                    actionsSubject.send(.presentResolveSendFailure(failure: failure,
                                                                   sendHandle: sendHandle))
                case .hasScrolled, .displayRoom, .displayMediaDetails:
                    break
                case .composer(let action):
                    composerViewModel.process(timelineAction: action)
                case .viewInRoomTimeline, .displayThread:
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
        
        // Loading the draft requires the subscriptions to be set up first otherwise
        // the room won't be be able to propagate the information to the composer.
        composerViewModel.start()
    }
    
    func stop() {
        composerViewModel.stop()
        viewModel.stop()
    }
        
    func toPresentable() -> AnyView {
        let composerToolbar = ComposerToolbar(context: composerViewModel.context)
        
        return AnyView(ThreadTimelineScreen(context: viewModel.context,
                                            timelineContext: timelineViewModel.context,
                                            composerToolbar: composerToolbar))
    }
    
    func focusOnEvent(eventID: String) {
        Task { await timelineViewModel.focusOnEvent(eventID: eventID) }
    }
}
