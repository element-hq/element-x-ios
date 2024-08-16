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

import Combine
import SFSafeSymbols
import SwiftUI
import WebKit

struct CallScreen: View {
    @ObservedObject var context: CallScreenViewModel.Context
    
    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { context.send(viewAction: .navigateBack) } label: {
                            Image(systemSymbol: .chevronBackward)
                                .fontWeight(.semibold)
                        }
                        .offset(y: -8)
                        // .padding(.leading, -8) // Fixes the button alignment, but harder to tap.
                    }
                }
        }
    }
    
    @ViewBuilder
    var content: some View {
        if context.viewState.url == nil {
            ProgressView()
        } else {
            WebView(url: context.viewState.url, viewModelContext: context)
                // This URL is stable, forces view reloads if this representable is ever reused for another url
                .id(context.viewState.url)
                .ignoresSafeArea(edges: .bottom)
                .presentationDragIndicator(.visible)
                .alert(item: $context.alertInfo)
        }
    }
}

private struct WebView: UIViewRepresentable {
    let url: URL?
    let viewModelContext: CallScreenViewModel.Context
    
    func makeUIView(context: Context) -> WKWebView {
        context.coordinator.webView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModelContext: viewModelContext)
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url {
            context.coordinator.url = url
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    @MainActor
    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        private weak var viewModelContext: CallScreenViewModel.Context?
        private let certificateValidator: CertificateValidatorHookProtocol
        
        private(set) var webView: WKWebView!
        
        var url: URL!
        
        init(viewModelContext: CallScreenViewModel.Context) {
            self.viewModelContext = viewModelContext
            certificateValidator = viewModelContext.viewState.certificateValidator
            
            super.init()
            
            DispatchQueue.main.async {
                // Avoid `Publishing changes from within view update warnings`
                viewModelContext.javaScriptEvaluator = self.evaluateJavaScript(_:)
            }
            
            let configuration = WKWebViewConfiguration()
            
            let userContentController = WKUserContentController()
            userContentController.add(WKScriptMessageHandlerWrapper(self), name: viewModelContext.viewState.messageHandler)
            
            configuration.userContentController = userContentController
            configuration.allowsInlineMediaPlayback = true
            configuration.allowsPictureInPictureMediaPlayback = true
            
            if let script = viewModelContext.viewState.script {
                let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
                configuration.userContentController.addUserScript(userScript)
            }
            
            webView = WKWebView(frame: .zero, configuration: configuration)
            webView.uiDelegate = self
            webView.navigationDelegate = self
            webView.isInspectable = true
            
            // https://stackoverflow.com/a/77963877/730924
            webView.allowsLinkPreview = true
            
            // Try matching Element Call colors
            webView.isOpaque = false
            webView.backgroundColor = .compound.bgCanvasDefault
            webView.scrollView.backgroundColor = .compound.bgCanvasDefault
        }
        
        func evaluateJavaScript(_ script: String) async throws -> Any? {
            // After testing different scenarios it seems that when using async/await version of these
            // methods wkwebView expects JavaScript to return with a value (something other than Void),
            // if there is no value returning from the JavaScript that you evaluate you will have a crash.
            try await withCheckedThrowingContinuation { [weak self] continuaton in
                self?.webView.evaluateJavaScript(script) { result, error in
                    if let error {
                        continuaton.resume(throwing: error)
                    } else {
                        continuaton.resume(returning: result)
                    }
                }
            }
        }
        
        nonisolated func userContentController(_ userContentController: WKUserContentController,
                                               didReceive message: WKScriptMessage) {
            Task { @MainActor [weak self] in
                self?.viewModelContext?.javaScriptMessageHandler?(message.body)
            }
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
        
        func webView(_ webView: WKWebView, respondTo challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
            await certificateValidator.respondTo(challenge)
        }
        
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
        
        nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                viewModelContext?.send(viewAction: .urlChanged(webView.url))
            }
        }
    }
    
    /// Avoids retain loops between the configuration and webView coordinator
    private class WKScriptMessageHandlerWrapper: NSObject, WKScriptMessageHandler {
        private weak var coordinator: Coordinator?
        
        init(_ coordinator: Coordinator) {
            self.coordinator = coordinator
        }
        
        // MARK: - WKScriptMessageHandler
        
        nonisolated func userContentController(_ userContentController: WKUserContentController,
                                               didReceive message: WKScriptMessage) {
            coordinator?.userContentController(userContentController, didReceive: message)
        }
    }
}

// MARK: - Previews

struct CallScreen_Previews: PreviewProvider {
    static let viewModel = {
        let clientProxy = ClientProxyMock()
        clientProxy.getElementWellKnownReturnValue = .success(nil)
        clientProxy.deviceID = "call-device-id"
        
        let roomProxy = RoomProxyMock()
        roomProxy.sendCallNotificationIfNeededReturnValue = .success(())
        
        let widgetDriver = ElementCallWidgetDriverMock()
        widgetDriver.underlyingMessagePublisher = .init()
        widgetDriver.underlyingActions = PassthroughSubject<ElementCallWidgetDriverAction, Never>().eraseToAnyPublisher()
        widgetDriver.startBaseURLClientIDColorSchemeReturnValue = .success(URL.userDirectory)
        
        roomProxy.elementCallWidgetDriverDeviceIDReturnValue = widgetDriver
        
        return CallScreenViewModel(elementCallService: ElementCallServiceMock(.init()),
                                   clientProxy: clientProxy,
                                   roomProxy: roomProxy,
                                   clientID: "io.element.elementx",
                                   elementCallBaseURL: "https://call.element.io",
                                   elementCallBaseURLOverride: nil,
                                   elementCallPictureInPictureEnabled: false,
                                   colorScheme: .light,
                                   appHooks: AppHooks())
    }()
    
    static var previews: some View {
        NavigationStack {
            CallScreen(context: viewModel.context)
        }
    }
}
