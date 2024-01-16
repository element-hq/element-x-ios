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

struct GenericCallLinkCoordinatorParameters {
    let url: URL
}

private enum GenericCallLinkQueryParameters {
    static let appPrompt = "appPrompt"
    static let confineToRoom = "confineToRoom"
}

class GenericCallLinkCoordinator: CoordinatorProtocol {
    private let parameters: GenericCallLinkCoordinatorParameters
    
    init(parameters: GenericCallLinkCoordinatorParameters) {
        self.parameters = parameters
    }
    
    func toPresentable() -> AnyView {
        AnyView(
            WebView(url: parameters.url)
                .id(UUID())
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
        Coordinator(url: url)
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: context.coordinator.url))
    }

    @MainActor
    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        let url: URL
        private(set) var webView: WKWebView!

        init(url: URL) {
            if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) {
                var fragmentQueryItems = urlComponents.fragmentQueryItems ?? []
                
                fragmentQueryItems.removeAll { $0.name == GenericCallLinkQueryParameters.appPrompt }
                fragmentQueryItems.removeAll { $0.name == GenericCallLinkQueryParameters.confineToRoom }
                
                fragmentQueryItems.append(.init(name: GenericCallLinkQueryParameters.appPrompt, value: "false"))
                fragmentQueryItems.append(.init(name: GenericCallLinkQueryParameters.confineToRoom, value: "true"))
                
                urlComponents.fragmentQueryItems = fragmentQueryItems
                
                if let adjustedURL = urlComponents.url {
                    self.url = adjustedURL
                } else {
                    MXLog.error("Failed adjusting URL with components: \(urlComponents)")
                    self.url = url
                }
            } else {
                MXLog.error("Failed constructing URL components for url: \(url)")
                self.url = url
            }
            
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
            guard origin.host == url.host else {
                return .deny
            }
            
            return .grant
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            // Allow any content from the main URL.
            if navigationAction.request.url?.host == url.host {
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
