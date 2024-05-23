//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import HTMLParser
import SwiftUI
import WysiwygComposer

struct RoomScreenCoordinatorParameters {
    let roomProxy: RoomProxyProtocol
    var focussedEventID: String?
    let timelineController: RoomTimelineControllerProtocol
    let mediaProvider: MediaProviderProtocol
    let mediaPlayerProvider: MediaPlayerProviderProtocol
    let voiceMessageMediaManager: VoiceMessageMediaManagerProtocol
    let emojiProvider: EmojiProviderProtocol
    let completionSuggestionService: CompletionSuggestionServiceProtocol
    let appMediator: AppMediatorProtocol
    let appSettings: AppSettings
    let draftService: ComposerDraftServiceProtocol
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
}

final class RoomScreenCoordinator: CoordinatorProtocol {
    private var viewModel: RoomScreenViewModelProtocol
    private var composerViewModel: ComposerToolbarViewModel
    private var wysiwygViewModel: WysiwygComposerViewModel

    private var cancellables = Set<AnyCancellable>()

    private let actionsSubject: PassthroughSubject<RoomScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<RoomScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomScreenCoordinatorParameters) {
        viewModel = RoomScreenViewModel(roomProxy: parameters.roomProxy,
                                        focussedEventID: parameters.focussedEventID,
                                        timelineController: parameters.timelineController,
                                        mediaProvider: parameters.mediaProvider,
                                        mediaPlayerProvider: parameters.mediaPlayerProvider,
                                        voiceMessageMediaManager: parameters.voiceMessageMediaManager,
                                        userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                        appMediator: parameters.appMediator,
                                        appSettings: parameters.appSettings,
                                        analyticsService: ServiceLocator.shared.analytics,
                                        notificationCenter: NotificationCenter.default)

        wysiwygViewModel = WysiwygComposerViewModel(minHeight: ComposerConstant.minHeight,
                                                    maxCompressedHeight: ComposerConstant.maxHeight,
                                                    maxExpandedHeight: ComposerConstant.maxHeight,
                                                    parserStyle: .elementX)
        composerViewModel = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel,
                                                     completionSuggestionService: parameters.completionSuggestionService,
                                                     mediaProvider: parameters.mediaProvider,
                                                     appSettings: parameters.appSettings,
                                                     mentionDisplayHelper: ComposerMentionDisplayHelper(roomContext: viewModel.context),
                                                     draftService: parameters.draftService)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }

                switch action {
                case .displayRoomDetails:
                    actionsSubject.send(.presentRoomDetails)
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
                case .displayRoomMemberDetails(userID: let userID):
                    actionsSubject.send(.presentRoomMemberDetails(userID: userID))
                case .displayMessageForwarding(let forwardingItem):
                    actionsSubject.send(.presentMessageForwarding(forwardingItem: forwardingItem))
                case .displayLocation(let body, let geoURI, let description):
                    actionsSubject.send(.presentLocationViewer(body: body, geoURI: geoURI, description: description))
                case .composer(let action):
                    composerViewModel.process(roomAction: action)
                case .displayCallScreen:
                    actionsSubject.send(.presentCallScreen)
                }
            }
            .store(in: &cancellables)

        composerViewModel.actions
            .sink { [weak self] action in
                guard let self else { return }

                viewModel.process(composerAction: action)
            }
            .store(in: &cancellables)
        
        viewModel.start()
    }
    
    func focusOnEvent(eventID: String) {
        Task { await viewModel.focusOnEvent(eventID: eventID) }
    }
    
    func stop() {
        viewModel.stop()
    }
    
    func toPresentable() -> AnyView {
        let composerToolbar = ComposerToolbar(context: composerViewModel.context,
                                              wysiwygViewModel: wysiwygViewModel,
                                              keyCommands: composerViewModel.keyCommands)

        return AnyView(RoomScreen(context: viewModel.context, composerToolbar: composerToolbar))
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
