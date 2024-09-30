//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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

    init(activityItems: [Any],
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

    func makeUIViewController(context: Context) -> UIViewControllerType {
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

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }

    static func dismantleUIViewController(_ uiViewController: UIViewControllerType, coordinator: Coordinator) {
        uiViewController.completionWithItemsHandler = nil
    }
}
