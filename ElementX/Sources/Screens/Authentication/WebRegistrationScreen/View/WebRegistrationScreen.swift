//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI
import WebKit

struct WebRegistrationScreen: View {
    @ObservedObject var context: WebRegistrationScreenViewModel.Context
    
    var body: some View {
        NavigationStack {
            WebRegistrationWebView(url: context.viewState.url, viewModelContext: context)
                .navigationTitle(L10n.screenCreateAccountTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.actionCancel) {
                            context.send(viewAction: .cancel)
                        }
                    }
                }
        }
    }
}

struct WebRegistrationWebView: UIViewRepresentable {
    let url: URL
    let viewModelContext: WebRegistrationScreenViewModel.Context
    
    func makeUIView(context: Context) -> WKWebView {
        context.coordinator.webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url, viewModelContext: viewModelContext)
    }
    
    class Coordinator: NSObject, WKUIDelegate {
        private let url: URL
        private let viewModelContext: WebRegistrationScreenViewModel.Context
        
        private(set) var webView: WKWebView!
        
        init(url: URL, viewModelContext: WebRegistrationScreenViewModel.Context) {
            self.url = url
            self.viewModelContext = viewModelContext
            
            super.init()
            
            let eventHandlerName = "elementx"
            let userContentController = WKUserContentController()
            userContentController.add(WKScriptMessageHandlerWrapper(self), name: eventHandlerName)
            
            let eventHandlerScript = """
            window.addEventListener(
                "mobileregistrationresponse",
                (event) => {
                    window.webkit.messageHandlers.\(eventHandlerName).postMessage(JSON.stringify(event.detail));
                },
                false,
              );
            """
            
            let userScript = WKUserScript(source: eventHandlerScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            userContentController.addUserScript(userScript)
            
            let configuration = WKWebViewConfiguration()
            configuration.userContentController = userContentController
            configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
            
            webView = WKWebView(frame: .zero, configuration: configuration)
            webView.uiDelegate = self
            webView.load(URLRequest(url: url))
        }
        
        nonisolated func userContentController(_ userContentController: WKUserContentController,
                                               didReceive message: WKScriptMessage) {
            guard let jsonString = message.body as? String, let jsonData = jsonString.data(using: .utf8) else {
                MXLog.error("Unexpected response.")
                return
            }
            
            guard let credentials = try? JSONDecoder().decode(WebRegistrationCredentials.self, from: jsonData) else {
                MXLog.error("Invalid response.")
                return
            }
            
            MXLog.info("Received login credentials.")
            Task { await viewModelContext.send(viewAction: .signedIn(credentials)) }
        }
        
        // MARK: WKUIDelegate
        
        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            return nil
        }
    }
    
    /// Avoids retain loops between the configuration and webView coordinator
    private class WKScriptMessageHandlerWrapper: NSObject, WKScriptMessageHandler {
        private weak var coordinator: Coordinator?
        
        init(_ coordinator: Coordinator) {
            self.coordinator = coordinator
        }
        
        // MARK: WKScriptMessageHandler
        
        nonisolated func userContentController(_ userContentController: WKUserContentController,
                                               didReceive message: WKScriptMessage) {
            coordinator?.userContentController(userContentController, didReceive: message)
        }
    }
}

// MARK: - Previews

struct WebRegistrationScreen_Previews: PreviewProvider {
    static let viewModel = WebRegistrationScreenViewModel(registrationHelperURL: "https://develop.element.io/#/mobile_register")
    static var previews: some View {
        NavigationStack {
            WebRegistrationScreen(context: viewModel.context)
        }
    }
}
