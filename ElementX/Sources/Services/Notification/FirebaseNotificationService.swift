//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import FirebaseCore
import FirebaseMessaging
import Foundation

/// Manages Firebase Cloud Messaging initialization and FCM token lifecycle.
///
/// On iOS, FCM is a wrapper around APNs. This service:
/// 1. Initializes the Firebase SDK (`FirebaseApp.configure()`)
/// 2. Receives FCM registration token updates via `MessagingDelegate`
/// 3. Exposes the current FCM token for pusher registration
final class FirebaseNotificationService: NSObject, MessagingDelegate {
    private var onTokenUpdate: ((String) -> Void)?

    /// Configures Firebase and starts listening for FCM token updates.
    /// - Parameter onTokenUpdate: Called whenever the FCM registration token is created or refreshed.
    func configure(onTokenUpdate: @escaping (String) -> Void) {
        self.onTokenUpdate = onTokenUpdate
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
    }

    /// Returns the current FCM registration token, if available.
    func currentToken() async -> String? {
        try? await Messaging.messaging().token()
    }

    // MARK: - MessagingDelegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else {
            MXLog.warning("Received nil FCM registration token")
            return
        }
        MXLog.info("FCM registration token updated")
        onTokenUpdate?(fcmToken)
    }
}
