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

typealias MediaPlayerViewModelType = StateStoreViewModel<MediaPlayerViewState, MediaPlayerViewAction>

class MediaPlayerViewModel: MediaPlayerViewModelType, MediaPlayerViewModelProtocol {
    var callback: ((MediaPlayerViewModelAction) -> Void)?

    init(mediaURL: URL, autoplay: Bool = true) {
        super.init(initialViewState: MediaPlayerViewState(mediaURL: mediaURL,
                                                          autoplay: autoplay))
    }
    
    override func process(viewAction: MediaPlayerViewAction) async {
        switch viewAction {
        case .cancel:
            callback?(.cancel)
        }
    }
}
