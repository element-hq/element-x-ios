//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import IntentsUI
import SwiftUI

class ShareExtensionViewController: UIViewController {
    private let appSettings: CommonSettingsProtocol = AppSettings()
    private let hostingController = UIHostingController(rootView: ShareExtensionView())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(hostingController)
        view.addMatchedSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        MXLog.configure(currentTarget: "shareextension", filePrefix: "shareextension", logLevel: appSettings.logLevel)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Task {
            if let payload = await prepareSharePayload() {
                await self.openMainApp(payload: payload)
            }
            
            self.dismiss()
        }
    }
    
    // MARK: - Private
    
    private func prepareSharePayload() async -> ShareExtensionPayload? {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            return nil
        }
        
        guard let contentType = itemProvider.preferredContentType,
              let preferredExtension = contentType.preferredFilenameExtension else {
            MXLog.error("Invalid NSItemProvider: \(itemProvider)")
            return nil
        }
        
        let roomID = (extensionContext?.intent as? INSendMessageIntent)?.conversationIdentifier
        let providerSuggestedName = itemProvider.suggestedName
        let providerDescription = itemProvider.description
        
        let shareData: Data? = await withCheckedContinuation { continuation in
            _ = itemProvider.loadDataRepresentation(for: contentType) { data, error in
                if let error {
                    MXLog.error("Failed processing NSItemProvider: \(providerDescription) with error: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let data else {
                    MXLog.error("Invalid NSItemProvider data: \(providerDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: data)
            }
        }
        
        guard let shareData else {
            return nil
        }
        
        do {
            let url: URL
            if let filename = providerSuggestedName {
                let hasExtension = !(filename as NSString).pathExtension.isEmpty
                let filename = hasExtension ? filename : "\(filename).\(preferredExtension)"
                url = try FileManager.default.writeDataToTemporaryDirectory(data: shareData, fileName: filename)
            } else {
                let filename = "\(UUID().uuidString).\(preferredExtension)"
                url = try FileManager.default.writeDataToTemporaryDirectory(data: shareData, fileName: filename)
            }
            
            return .mediaFile(roomID: roomID, mediaFile: .init(url: url, suggestedName: providerSuggestedName))
        } catch {
            MXLog.error("Failed storing NSItemProvider data \(providerDescription) with error: \(error)")
            return nil
        }
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
