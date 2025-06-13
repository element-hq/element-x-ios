//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import HTMLParser
import SwiftUI
import WysiwygComposer

struct ThreadTimelineScreenCoordinatorParameters {
    let clientProxy: ClientProxyProtocol
    let roomProxy: JoinedRoomProxyProtocol
    let timelineController: TimelineControllerProtocol
    let mediaProvider: MediaProviderProtocol
    let mediaPlayerProvider: MediaPlayerProviderProtocol
    let voiceMessageMediaManager: VoiceMessageMediaManagerProtocol
    let emojiProvider: EmojiProviderProtocol
    let completionSuggestionService: CompletionSuggestionServiceProtocol
    let appMediator: AppMediatorProtocol
    let appSettings: AppSettings
    let composerDraftService: ComposerDraftServiceProtocol
    let timelineControllerFactory: TimelineControllerFactoryProtocol
}

enum ThreadTimelineScreenCoordinatorAction {
    case presentReportContent(itemID: TimelineItemIdentifier, senderID: String)
    case presentMediaUploadPicker(MediaPickerScreenSource, threadRootEventID: String?)
    case presentMediaUploadPreviewScreen(url: URL, threadRootEventID: String?)
    case presentLocationPicker(threadRootEventID: String?)
    case presentLocationViewer(body: String, geoURI: GeoURI, description: String?, threadRootEventID: String?)
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
        
        viewModel = ThreadTimelineScreenViewModel(roomProxy: parameters.roomProxy)
        
        timelineViewModel = TimelineViewModel(roomProxy: parameters.roomProxy,
                                              timelineController: parameters.timelineController,
                                              mediaProvider: parameters.mediaProvider,
                                              mediaPlayerProvider: parameters.mediaPlayerProvider,
                                              voiceMessageMediaManager: parameters.voiceMessageMediaManager,
                                              userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                              appMediator: parameters.appMediator,
                                              appSettings: parameters.appSettings,
                                              analyticsService: ServiceLocator.shared.analytics,
                                              emojiProvider: parameters.emojiProvider,
                                              timelineControllerFactory: parameters.timelineControllerFactory,
                                              clientProxy: parameters.clientProxy)
        
        let wysiwygViewModel = WysiwygComposerViewModel(minHeight: ComposerConstant.minHeight,
                                                        maxCompressedHeight: ComposerConstant.maxHeight,
                                                        maxExpandedHeight: ComposerConstant.maxHeight,
                                                        parserStyle: .elementX)
        
        composerViewModel = ComposerToolbarViewModel(initialText: nil,
                                                     roomProxy: parameters.roomProxy,
                                                     isInThread: true,
                                                     wysiwygViewModel: wysiwygViewModel,
                                                     completionSuggestionService: parameters.completionSuggestionService,
                                                     mediaProvider: parameters.mediaProvider,
                                                     mentionDisplayHelper: ComposerMentionDisplayHelper(timelineContext: timelineViewModel.context),
                                                     appSettings: parameters.appSettings,
                                                     analyticsService: ServiceLocator.shared.analytics,
                                                     composerDraftService: parameters.composerDraftService)
    }
    
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
                    actionsSubject.send(.presentMediaUploadPicker(.camera,
                                                                  threadRootEventID: parameters.timelineController.timelineKind.threadRootEventID))
                case .displayMediaPicker:
                    actionsSubject.send(.presentMediaUploadPicker(.photoLibrary,
                                                                  threadRootEventID: parameters.timelineController.timelineKind.threadRootEventID))
                case .displayDocumentPicker:
                    actionsSubject.send(.presentMediaUploadPicker(.documents,
                                                                  threadRootEventID: parameters.timelineController.timelineKind.threadRootEventID))
                case .displayMediaPreview(let mediaPreviewViewModel):
                    viewModel.displayMediaPreview(mediaPreviewViewModel)
                case .displayLocationPicker:
                    actionsSubject.send(.presentLocationPicker(threadRootEventID: parameters.timelineController.timelineKind.threadRootEventID))
                case .displayLocation(let body, let geoURI, let description):
                    actionsSubject.send(.presentLocationViewer(body: body,
                                                               geoURI: geoURI,
                                                               description: description, threadRootEventID: parameters.timelineController.timelineKind.threadRootEventID))
                case .displayPollForm(let mode):
                    actionsSubject.send(.presentPollForm(mode: mode))
                case .displayMediaUploadPreviewScreen(let url):
                    actionsSubject.send(.presentMediaUploadPreviewScreen(url: url,
                                                                         threadRootEventID: parameters.timelineController.timelineKind.threadRootEventID))
                case .displaySenderDetails(userID: let userID):
                    actionsSubject.send(.presentRoomMemberDetails(userID: userID))
                case .displayMessageForwarding(let forwardingItem):
                    actionsSubject.send(.presentMessageForwarding(forwardingItem: forwardingItem))
                case .displayResolveSendFailure(let failure, let sendHandle):
                    actionsSubject.send(.presentResolveSendFailure(failure: failure,
                                                                   sendHandle: sendHandle))
                case .hasScrolled, .displayRoom:
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
}
