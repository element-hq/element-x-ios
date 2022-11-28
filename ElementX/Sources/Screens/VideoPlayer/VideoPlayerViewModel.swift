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

import SwiftUI

typealias VideoPlayerViewModelType = StateStoreViewModel<VideoPlayerViewState, VideoPlayerViewAction>

class VideoPlayerViewModel: VideoPlayerViewModelType, VideoPlayerViewModelProtocol {
    var callback: ((VideoPlayerViewModelAction) -> Void)?

    init(videoURL: URL, autoplay: Bool = true, isModallyPresented: Bool = true) {
        super.init(initialViewState: VideoPlayerViewState(videoURL: videoURL,
                                                          autoplay: autoplay,
                                                          isModallyPresented: isModallyPresented))
    }
    
    override func process(viewAction: VideoPlayerViewAction) async {
        switch viewAction {
        case .cancel:
            callback?(.cancel)
        }
    }
}
