//
// Copyright 2023 New Vector Ltd
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
import SwiftUI

typealias VoiceRoomPlaybackViewModelType = StateStoreViewModel<VoiceRoomPlaybackViewState, VoiceRoomPlaybackViewAction>

class VoiceRoomPlaybackViewModel: VoiceRoomPlaybackViewModelType, VoiceRoomPlaybackViewModelProtocol, ObservableObject {
    private let actionsSubject: PassthroughSubject<VoiceRoomPlaybackViewModelAction, Never> = .init()
    
    private static let elapsedTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "m:ss"
        return dateFormatter
    }()
    
    var actions: AnyPublisher<VoiceRoomPlaybackViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(timelineItem: VoiceRoomTimelineItem) {
        let bindings = VoiceRoomPlaybackViewStateBindings()
        super.init(initialViewState: VoiceRoomPlaybackViewState(bindings: bindings,
                                                                duration: timelineItem.content.duration,
                                                                waveform: timelineItem.content.waveform ?? Waveform(data: [])))
    }
        
    // MARK: - Public
    
    override func process(viewAction: VoiceRoomPlaybackViewAction) {
        switch viewAction {
        case .seek(let position):
            state.progress = position
            state.currentTime = Self.elapsedTimeFormatter.string(for: Date(timeIntervalSinceReferenceDate: state.duration * state.progress)) ?? "-:--"
        case .playPauseButtonTapped:
            state.playing.toggle()
        }
    }
    
    // MARK: - Private

    private func displayError(_ type: VoiceRoomPlaybackViewErrorType) {
        switch type {
        case .loadingFailed:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: L10n.commonError,
                                                 message: "Failed to load audio content")
        }
    }
}
