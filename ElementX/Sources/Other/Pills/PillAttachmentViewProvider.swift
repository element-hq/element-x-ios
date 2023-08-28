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

import SwiftUI
import UIKit

final class PillAttachmentViewProvider: NSTextAttachmentViewProvider {
    private var isXcodePreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    // MARK: - Override

    override func loadView() {
        super.loadView()

        guard textAttachment is PillTextAttachment else {
            MXLog.failure("[PillAttachmentViewProvider]: attachment is missing or not of expected class")
            return
        }

        let imageProvider = isXcodePreview ? MockMediaProvider() : Self.currentSession?.mediaProvider
        let view = PillView(imageProvider: imageProvider)
        let controller = UIHostingController(rootView: view)
        self.view = controller.view
    }
}

extension PillAttachmentViewProvider {
    // This is a bit of an hack, since the Provider is instantiated by the system we have no way to pass the current session it, so we need to inject it globally.
    static var currentSession: UserSessionProtocol?
}
