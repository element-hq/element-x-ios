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

typealias ReportContentViewModelType = StateStoreViewModel<ReportContentViewState, ReportContentViewAction>

class ReportContentViewModel: ReportContentViewModelType, ReportContentViewModelProtocol {
    var callback: ((ReportContentViewModelAction) -> Void)?

    private let itemID: String
    private let timelineController: RoomTimelineControllerProtocol

    init(itemID: String, timelineController: RoomTimelineControllerProtocol) {
        self.itemID = itemID
        self.timelineController = timelineController
        super.init(initialViewState: ReportContentViewState(bindings: ReportContentViewStateBindings(reasonText: "")))
    }

    // MARK: - Public
    
    override func process(viewAction: ReportContentViewAction) async {
        switch viewAction {
        case .cancel:
            callback?(.cancel)
        case .submit:
            callback?(.submitStarted)
        }
    }
}
