//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVKit
import Foundation

enum CallScreenViewModelAction {
    case pictureInPictureIsAvailable(AVPictureInPictureController)
    case pictureInPictureStarted
    case pictureInPictureStopped
    case dismiss
}

struct CallScreenViewState: BindableState {
    let script: String?
    var url: URL?
    let isGenericCallLink: Bool
    
    let certificateValidator: CertificateValidatorHookProtocol
    
    var bindings = Bindings()
}

struct Bindings {
    var javaScriptEvaluator: ((String) async throws -> Any)?
    var requestPictureInPictureHandler: (() async -> Result<Void, CallScreenError>)?
    
    var alertInfo: AlertInfo<UUID>?
}

enum CallScreenViewAction {
    case urlChanged(URL?)
    case pictureInPictureIsAvailable(AVPictureInPictureController)
    case navigateBack
    case pictureInPictureWillStop
    case endCall
    case mediaCapturePermissionGranted
    case outputDeviceSelected(deviceID: String)
    case widgetAction(message: String)
}

enum CallScreenError: Error {
    case pictureInPictureNotAvailable
}

/// Identifies each event handler used by the CallScreen webview
///
/// The names of the enum need to always match the name of the handlers on the webview.
enum CallScreenJavaScriptMessageName: String, CaseIterable {
    /// Widget actions's handler.
    case widgetAction
    /// Used to show the native AVRoutePickerView.
    case showNativeOutputDevicePicker
    /// Used to determine if the webview has selected the earpiece or not.
    case onOutputDeviceSelect
    /// Used to handle the webview back button
    case onBackButtonPressed
    
    private var postMessageScript: String {
        switch self {
        case .widgetAction:
            """
            window.addEventListener(
                "message",
                (event) => {
                    let message = {data: event.data, origin: event.origin};
                    if (message.data.response && message.data.api == "toWidget"
                    || !message.data.response && message.data.api == "fromWidget") {
                        window.webkit.messageHandlers.\(rawValue).postMessage(JSON.stringify(message.data));
                    } else {
                        console.log("-- skipped event handling by the client because it is send from the client itself.");
                    }
                },
                false,
            );
            """
        case .showNativeOutputDevicePicker:
            """
            window.controls.\(rawValue) = () => {
                window.webkit.messageHandlers.\(rawValue).postMessage("");
            };
            """
        case .onOutputDeviceSelect:
            """
            window.controls.\(rawValue) = (id) => {
                window.webkit.messageHandlers.\(rawValue).postMessage(id);
            };
            """
        case .onBackButtonPressed:
            """
            window.controls.\(rawValue) = () => {
                window.webkit.messageHandlers.\(rawValue).postMessage("");
            }
            """
        }
    }
    
    static var allCasesInjectionScript: String {
        allCases.map(\.postMessageScript).joined(separator: "\n")
    }
}

struct DecodedWidgetMessage: Decodable {
    private static let decoder = JSONDecoder()
    private static let contentLoadedAction = "content_loaded"
    private static let fromWidget = "fromWidget"
    
    let action: String?
    let api: String?
    
    static func decode(message: String) throws -> DecodedWidgetMessage? {
        guard let data = message.data(using: .utf8) else {
            return nil
        }
        return try decoder.decode(DecodedWidgetMessage.self, from: data)
    }
    
    var hasLoaded: Bool {
        action == Self.contentLoadedAction && api == Self.fromWidget
    }
}
