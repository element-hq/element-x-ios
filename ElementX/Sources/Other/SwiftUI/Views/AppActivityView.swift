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

struct AppActivityView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIActivityViewController
    typealias CompletionType = (Result<(activity: UIActivity.ActivityType, items: [Any]?), Error>) -> Void

    private let activityItems: [Any]
    private let applicationActivities: [UIActivity]?
    private var excludedActivityTypes: [UIActivity.ActivityType]
    private var onCancel: (() -> Void)?
    private var onComplete: CompletionType?

    public init(activityItems: [Any],
                applicationActivities: [UIActivity]? = nil,
                excludedActivityTypes: [UIActivity.ActivityType] = [],
                onCancel: (() -> Void)? = nil,
                onComplete: CompletionType? = nil) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
        self.excludedActivityTypes = excludedActivityTypes
        self.onCancel = onCancel
        self.onComplete = onComplete
    }

    public func makeUIViewController(context: Context) -> UIViewControllerType {
        let viewController = UIViewControllerType(activityItems: activityItems, applicationActivities: applicationActivities)
        viewController.excludedActivityTypes = excludedActivityTypes

        viewController.completionWithItemsHandler = { activity, completed, items, error in
            if let error {
                onComplete?(.failure(error))
            } else if let activity, completed {
                onComplete?(.success((activity, items)))
            } else if !completed {
                onCancel?()
            } else {
                assertionFailure()
            }
        }

        return viewController
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }

    public static func dismantleUIViewController(_ uiViewController: UIViewControllerType, coordinator: Coordinator) {
        uiViewController.completionWithItemsHandler = nil
    }
}
