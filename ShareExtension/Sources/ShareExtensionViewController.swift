//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import IntentsUI
import SwiftUI

class ShareExtensionViewController: UIViewController {
    private static var targetConfiguration: Target.ConfigurationResult?
    private let appSettings: CommonSettingsProtocol = AppSettings()
    private var appHooks: AppHooks!
    
    private let keychainController = KeychainController(service: .sessions,
                                                        accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
    
    private var cancellables: Set<AnyCancellable> = []
    
    private let hostingController = UIHostingController(rootView: ShareExtensionView())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appHooks = AppHooks()
        appHooks.setUp()
        
        if Self.targetConfiguration == nil {
            Self.targetConfiguration = Target.shareExtension.configure(logLevel: appSettings.logLevel,
                                                                       traceLogPacks: appSettings.traceLogPacks,
                                                                       sentryURL: nil,
                                                                       rageshakeURL: appSettings.bugReportRageshakeURL,
                                                                       appHooks: appHooks)
        }
        
        addChild(hostingController)
        view.addMatchedSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let credentials = keychainController.restorationTokens().first {
            let homeserverURL = credentials.restorationToken.session.homeserverUrl
            appHooks.remoteSettingsHook.loadCache(forHomeserver: homeserverURL, applyingTo: appSettings)
        } else {
            // We should really show a different state when there isn't a logged in user, but for now this is fine.
            MXLog.error("Not logged in, launching app to show the authentication flow.")
        }
        
        Task {
            if let payload = await prepareSharePayload() {
                await self.openMainApp(payload: payload)
            }
            
            self.dismiss()
        }
    }
    
    // MARK: - Private
    
    private func prepareSharePayload() async -> ShareExtensionPayload? {
        guard let extensionContext,
              let extensionItem = extensionContext.inputItems.first as? NSExtensionItem,
              let itemProviders = extensionItem.attachments else {
            return nil
        }
        
        let roomID = (extensionContext.intent as? INSendMessageIntent)?.conversationIdentifier
        
        var mediaFiles = [ShareExtensionMediaFile]()
        for itemProvider in itemProviders {
            if let fileURL = await itemProvider.storeData(withinAppGroupContainer: true) {
                mediaFiles.append(.init(url: fileURL, suggestedName: fileURL.lastPathComponent))
            } else if let url = await itemProvider.loadTransferable(type: URL.self) {
                return .text(roomID: roomID, text: url.absoluteString)
            } else if let string = await itemProvider.loadString() {
                return .text(roomID: roomID, text: string)
            } else {
                MXLog.error("Failed loading NSItemProvider data: \(itemProvider)")
            }
        }
        
        if !mediaFiles.isEmpty {
            return .mediaFiles(roomID: roomID, mediaFiles: mediaFiles)
        }
        
        return nil
    }
    
    private func openMainApp(payload: ShareExtensionPayload) async {
        guard let payload = urlEncodeSharePayload(payload) else {
            MXLog.error("Failed preparing share payload")
            return
        }
        
        guard let url = URL(string: "\(InfoPlistReader.main.baseBundleIdentifier):/\(ShareExtensionConstants.urlPath)?\(payload)") else {
            MXLog.error("Failed retrieving main application scheme")
            return
        }
        
        await openURL(url)
    }
    
    private func urlEncodeSharePayload(_ payload: ShareExtensionPayload) -> String? {
        let data: Data
        do {
            data = try JSONEncoder().encode(payload)
        } catch {
            MXLog.error("Failed encoding share payload with error: \(error)")
            return nil
        }
        
        guard let jsonString = String(data: data, encoding: .utf8) else {
            MXLog.error("Invalid payload data")
            return nil
        }
        
        return jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    private func dismiss() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    private func openURL(_ url: URL) async {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                await application.open(url)
                return
            }
            
            responder = responder?.next
        }
    }
}
