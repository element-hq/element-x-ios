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

import AVKit
import SwiftUI

struct VideoPlayerCoordinatorParameters {
    let videoURL: URL
}

enum VideoPlayerCoordinatorAction {
    case cancel
}

final class VideoPlayerCoordinator: CoordinatorProtocol {
    private let parameters: VideoPlayerCoordinatorParameters
    private var viewModel: VideoPlayerViewModelProtocol
    
    #warning("FIXME INDICATORS")
//    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var activityIndicator: UserIndicator?
    
    var callback: ((VideoPlayerCoordinatorAction) -> Void)?
    
    init(parameters: VideoPlayerCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = VideoPlayerViewModel(videoURL: parameters.videoURL)
        
        //indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: videoPlayerHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        configureAudioSession(.sharedInstance())

        viewModel.callback = { [weak self] action in
            guard let self else { return }
            MXLog.debug("VideoPlayerViewModel did complete with result: \(action).")
            switch action {
            case .cancel:
                self.callback?(.cancel)
            }
        }
    }
    
    func toPresentable() -> AnyView {
        AnyView(VideoPlayerScreen(context: viewModel.context))
    }

    func stop() {
        stopLoading()
    }
    
    // MARK: - Private

    private func configureAudioSession(_ session: AVAudioSession) {
        do {
            try session.setCategory(.playback,
                                    mode: .default,
                                    options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            MXLog.debug("Configure audio session failed: \(error)")
        }
    }
    
    /// Show an activity indicator whilst loading.
    /// - Parameters:
    ///   - label: The label to show on the indicator.
    ///   - isInteractionBlocking: Whether the indicator should block any user interaction.
    private func startLoading(label: String = ElementL10n.loading, isInteractionBlocking: Bool = true) {
//        activityIndicator = indicatorPresenter.present(.loading(label: label, isInteractionBlocking: isInteractionBlocking))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
//        activityIndicator = nil
    }
}
