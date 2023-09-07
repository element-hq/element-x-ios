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
import WebKit

struct GenericLinkCoordinatorParameters {
    let url: URL
}

class GenericCallLinkCoordinator: CoordinatorProtocol {
    private let parameters: GenericLinkCoordinatorParameters
    
    init(parameters: GenericLinkCoordinatorParameters) {
        self.parameters = parameters
    }
    
    func toPresentable() -> AnyView {
        AnyView(
            WebView(url: parameters.url)
                .ignoresSafeArea(edges: .bottom)
                .presentationDragIndicator(.visible)
        )
    }
}

private struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        context.coordinator.webView
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(initialURL: url)
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }

    @MainActor
    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        private let initialURL: URL
        private(set) var webView: WKWebView!

        init(initialURL: URL) {
            self.initialURL = initialURL
            super.init()
            
            let configuration = WKWebViewConfiguration()

            configuration.allowsInlineMediaPlayback = true
            configuration.allowsPictureInPictureMediaPlayback = true
            
            webView = WKWebView(frame: .zero, configuration: configuration)
            webView.uiDelegate = self
        }

        // MARK: - WKUIDelegate
        
        func webView(_ webView: WKWebView, decideMediaCapturePermissionsFor origin: WKSecurityOrigin, initiatedBy frame: WKFrameInfo, type: WKMediaCaptureType) async -> WKPermissionDecision {
            // Don't allow permissions for domains different than what the call was started on
            guard origin.host == initialURL.host else {
                return .deny
            }
            
            return .grant
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            // Allow any content from the main URL.
            if navigationAction.request.url?.host == initialURL.host {
                return .allow
            }
            
            // Additionally allow any embedded content such as captchas.
            if let targetFrame = navigationAction.targetFrame, !targetFrame.isMainFrame {
                return .allow
            }
            
            // Otherwise the request is invalid.
            return .cancel
        }
    }
}
