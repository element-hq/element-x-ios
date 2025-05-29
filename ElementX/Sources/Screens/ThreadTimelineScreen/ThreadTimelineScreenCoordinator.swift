//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct ThreadTimelineScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let timelineController: TimelineControllerProtocol
    let mediaProvider: MediaProviderProtocol
    let mediaPlayerProvider: MediaPlayerProviderProtocol
    let voiceMessageMediaManager: VoiceMessageMediaManagerProtocol
    let appMediator: AppMediatorProtocol
    let emojiProvider: EmojiProviderProtocol
    let timelineControllerFactory: TimelineControllerFactoryProtocol
    let clientProxy: ClientProxyProtocol
}

enum ThreadTimelineScreenCoordinatorAction {
    case presentReportContent(itemID: TimelineItemIdentifier, senderID: String)
    case presentMediaUploadPicker(MediaPickerScreenSource)
    case presentMediaUploadPreviewScreen(URL)
    case presentLocationPicker
    case presentPollForm(mode: PollFormMode)
    case presentLocationViewer(body: String, geoURI: GeoURI, description: String?)
    case presentEmojiPicker(itemID: TimelineItemIdentifier, selectedEmojis: Set<String>)
    case presentRoomMemberDetails(userID: String)
    case presentMessageForwarding(forwardingItem: MessageForwardingItem)
    case presentResolveSendFailure(failure: TimelineItemSendFailure.VerifiedUser, sendHandle: SendHandleProxy)
}

final class ThreadTimelineScreenCoordinator: CoordinatorProtocol {
    private let parameters: ThreadTimelineScreenCoordinatorParameters
    private let viewModel: ThreadTimelineScreenViewModelProtocol
    private let timelineViewModel: TimelineViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<ThreadTimelineScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<ThreadTimelineScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: ThreadTimelineScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = ThreadTimelineScreenViewModel()
        
        timelineViewModel = TimelineViewModel(roomProxy: parameters.roomProxy,
                                              timelineController: parameters.timelineController,
                                              mediaProvider: parameters.mediaProvider,
                                              mediaPlayerProvider: parameters.mediaPlayerProvider,
                                              voiceMessageMediaManager: parameters.voiceMessageMediaManager,
                                              userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                              appMediator: parameters.appMediator,
                                              appSettings: ServiceLocator.shared.settings,
                                              analyticsService: ServiceLocator.shared.analytics,
                                              emojiProvider: parameters.emojiProvider,
                                              timelineControllerFactory: parameters.timelineControllerFactory,
                                              clientProxy: parameters.clientProxy)
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
                    actionsSubject.send(.presentMediaUploadPicker(.camera))
                case .displayMediaPicker:
                    actionsSubject.send(.presentMediaUploadPicker(.photoLibrary))
                case .displayDocumentPicker:
                    actionsSubject.send(.presentMediaUploadPicker(.documents))
                case .displayMediaPreview(let mediaPreviewViewModel):
                    viewModel.displayMediaPreview(mediaPreviewViewModel)
                case .displayLocationPicker:
                    actionsSubject.send(.presentLocationPicker)
                case .displayPollForm(let mode):
                    actionsSubject.send(.presentPollForm(mode: mode))
                case .displayMediaUploadPreviewScreen(let url):
                    actionsSubject.send(.presentMediaUploadPreviewScreen(url))
                case .displaySenderDetails(userID: let userID):
                    actionsSubject.send(.presentRoomMemberDetails(userID: userID))
                case .displayMessageForwarding(let forwardingItem):
                    actionsSubject.send(.presentMessageForwarding(forwardingItem: forwardingItem))
                case .displayLocation(let body, let geoURI, let description):
                    actionsSubject.send(.presentLocationViewer(body: body, geoURI: geoURI, description: description))
                case .displayResolveSendFailure(let failure, let sendHandle):
                    actionsSubject.send(.presentResolveSendFailure(failure: failure, sendHandle: sendHandle))
                case .displayThread, .composer, .hasScrolled:
                    break
                case .viewInRoomTimeline:
                    fatalError("The action: \(action) should not be sent to this coordinator")
                }
            }
            .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }
        
    func toPresentable() -> AnyView {
        AnyView(ThreadTimelineScreen(context: viewModel.context, timelineContext: timelineViewModel.context))
    }
}
