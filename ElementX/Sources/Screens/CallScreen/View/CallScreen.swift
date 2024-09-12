//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AVKit
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
                        // .padding(.leading, -8) // Fixes the button alignment, but harder to tap.
                    }
                }
        }
        .alert(item: $context.alertInfo)
    }
    
    @ViewBuilder
    var content: some View {
        if context.viewState.url == nil {
            ProgressView()
        } else {
            CallView(url: context.viewState.url, viewModelContext: context)
                // This URL is stable, forces view reloads if this representable is ever reused for another url
                .id(context.viewState.url)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

private struct CallView: UIViewRepresentable {
    /// The top-level view this representable displays. It wraps the web view when picture in picture isn't running.
    typealias WebViewWrapper = UIView
    
    let url: URL?
    let viewModelContext: CallScreenViewModel.Context
    
    func makeUIView(context: Context) -> WebViewWrapper {
        context.coordinator.webViewWrapper
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModelContext: viewModelContext)
    }
    
    func updateUIView(_ callWebView: WebViewWrapper, context: Context) {
        if let url {
            context.coordinator.load(url)
        }
    }
    
    @MainActor
    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate, AVPictureInPictureControllerDelegate {
        private weak var viewModelContext: CallScreenViewModel.Context?
        private let certificateValidator: CertificateValidatorHookProtocol
        
        private var webView: WKWebView!
        private var pictureInPictureController: AVPictureInPictureController?
        private let pictureInPictureViewController: AVPictureInPictureVideoCallViewController
        
        /// The view to be shown in the app. This will contain the web view when picture in picture isn't running.
        let webViewWrapper = WebViewWrapper(frame: .zero)
        
        private var url: URL!
        
        init(viewModelContext: CallScreenViewModel.Context) {
            self.viewModelContext = viewModelContext
            certificateValidator = viewModelContext.viewState.certificateValidator
            pictureInPictureViewController = AVPictureInPictureVideoCallViewController()
            pictureInPictureViewController.preferredContentSize = CGSize(width: 1920, height: 1080)
            
            super.init()
            
            DispatchQueue.main.async { // Avoid `Publishing changes from within view update` warnings
                viewModelContext.javaScriptEvaluator = self.evaluateJavaScript
                viewModelContext.requestPictureInPictureHandler = self.requestPictureInPicture
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
            
            webViewWrapper.addMatchedSubview(webView)
            
            if AVPictureInPictureController.isPictureInPictureSupported() {
                let pictureInPictureController = AVPictureInPictureController(contentSource: .init(activeVideoCallSourceView: webViewWrapper,
                                                                                                   contentViewController: pictureInPictureViewController))
                pictureInPictureController.delegate = self
                self.pictureInPictureController = pictureInPictureController
                viewModelContext.send(viewAction: .pictureInPictureIsAvailable(pictureInPictureController))
            }
        }
        
        func load(_ url: URL) {
            self.url = url
            let request = URLRequest(url: url)
            webView.load(request)
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
        
        // MARK: - Picture in Picture
        
        func requestPictureInPicture() async -> Result<AVPictureInPictureController, CallScreenError> {
            guard let pictureInPictureController,
                  pictureInPictureController.isPictureInPicturePossible,
                  case .success(true) = await webViewCanEnterPictureInPicture() else {
                return .failure(.pictureInPictureNotAvailable)
            }
            
            pictureInPictureController.startPictureInPicture()
            return .success(pictureInPictureController)
        }
        
        func stopPictureInPicture() {
            pictureInPictureController?.stopPictureInPicture()
        }
        
        nonisolated func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            Task { @MainActor in
                // We move the view via the delegate so it works when you background the app without calling requestPictureInPicture
                pictureInPictureViewController.view.addMatchedSubview(webView)
                _ = try? await evaluateJavaScript("controls.enablePip()")
            }
        }
        
        nonisolated func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            Task { @MainActor in
                // Double check that the controller is definitely showing a page that supports picture in picture.
                // This is necessary as it doesn't get checked when backgrounding the app or tapping a notification.
                guard case .success(true) = await webViewCanEnterPictureInPicture() else {
                    MXLog.error("Picture in picture started on a webpage that doesn't support it. Ending the call.")
                    viewModelContext?.send(viewAction: .endCall)
                    return
                }
            }
        }
        
        nonisolated func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            Task { await viewModelContext?.send(viewAction: .pictureInPictureWillStop) }
        }
        
        nonisolated func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
            Task { @MainActor in
                webViewWrapper.addMatchedSubview(webView)
                _ = try? await evaluateJavaScript("controls.disablePip()")
            }
        }
        
        /// Whether the web view can do picture in picture or not (e.g. it is showing an error or the page didn't load).
        private func webViewCanEnterPictureInPicture() async -> Result<Bool, CallScreenError> {
            do {
                guard let canEnterPictureInPicture = try await evaluateJavaScript("controls.canEnterPip()") as? Bool else {
                    MXLog.error("canEnterPip returned an unexpected value, skipping picture in picture.")
                    return .failure(.pictureInPictureNotAvailable)
                }
                MXLog.info("canEnterPip returned \(canEnterPictureInPicture)")
                return .success(canEnterPictureInPicture)
            } catch {
                MXLog.error("Error checking canEnterPip: \(error)")
                return .failure(.pictureInPictureNotAvailable)
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
        
        let roomProxy = JoinedRoomProxyMock()
        roomProxy.sendCallNotificationIfNeededReturnValue = .success(())
        
        let widgetDriver = ElementCallWidgetDriverMock()
        widgetDriver.underlyingMessagePublisher = .init()
        widgetDriver.underlyingActions = PassthroughSubject<ElementCallWidgetDriverAction, Never>().eraseToAnyPublisher()
        widgetDriver.startBaseURLClientIDColorSchemeReturnValue = .success(URL.userDirectory)
        
        roomProxy.elementCallWidgetDriverDeviceIDReturnValue = widgetDriver
        
        return CallScreenViewModel(elementCallService: ElementCallServiceMock(.init()),
                                   configuration: .init(roomProxy: roomProxy,
                                                        clientProxy: clientProxy,
                                                        clientID: "io.element.elementx",
                                                        elementCallBaseURL: "https://call.element.io",
                                                        elementCallBaseURLOverride: nil,
                                                        colorScheme: .light),
                                   allowPictureInPicture: false,
                                   appHooks: AppHooks())
    }()
    
    static var previews: some View {
        NavigationStack {
            CallScreen(context: viewModel.context)
        }
    }
}
