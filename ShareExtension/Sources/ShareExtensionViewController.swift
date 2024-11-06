//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

class ShareExtensionViewController: UIViewController {
    private let appSettings: CommonSettingsProtocol = AppSettings()
    private let hostingController = UIHostingController(rootView: ShareExtensionView())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        NSLayoutConstraint.activate([view.topAnchor.constraint(equalTo: hostingController.view.topAnchor),
                                     view.leftAnchor.constraint(equalTo: hostingController.view.leftAnchor),
                                     view.bottomAnchor.constraint(equalTo: hostingController.view.bottomAnchor),
                                     view.rightAnchor.constraint(equalTo: hostingController.view.rightAnchor)])
        
        MXLog.configure(currentTarget: "shareextension", filePrefix: "shareextension", logLevel: appSettings.logLevel)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        processShare()
    }
    
    // MARK: - Private
    
    private func processShare() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            return
        }
        
        guard let contentType = itemProvider.preferredContentType,
              let preferredExtension = contentType.preferredFilenameExtension else {
            MXLog.error("Invalid NSItemProvider: \(itemProvider)")
            return
        }
        
        let providerSuggestedName = itemProvider.suggestedName
        let providerDescription = itemProvider.description
        
        _ = itemProvider.loadDataRepresentation(for: contentType) { [weak self] data, error in
            guard let self else { return }
            
            if let error {
                MXLog.error("Failed processing NSItemProvider: \(providerDescription) with error: \(error)")
                return
            }
            
            guard let data else {
                MXLog.error("Invalid NSItemProvider data: \(providerDescription)")
                return
            }
            
            do {
                let url: URL
                if let filename = providerSuggestedName {
                    let hasExtension = !(filename as NSString).pathExtension.isEmpty
                    let filename = hasExtension ? filename : "\(filename).\(preferredExtension)"
                    url = try FileManager.default.writeDataToTemporaryDirectory(data: data, fileName: filename)
                } else {
                    let filename = "\(UUID().uuidString).\(preferredExtension)"
                    url = try FileManager.default.writeDataToTemporaryDirectory(data: data, fileName: filename)
                }
                
                Task {
                    await self.openMainApp(payload: .mediaFile(roomID: "!POTexKBdzTfplmDWTc:matrix.org", mediaFile: .init(url: url, suggestedName: providerSuggestedName)))
                    await self.dismiss()
                }
            } catch {
                MXLog.error("Failed storing NSItemProvider data \(providerDescription) with error: \(error)")
            }
        }
    }
    
    private func openMainApp(payload: ShareExtensionPayload) async {
        guard let payload = urlEncodeSharePayload(payload) else {
            MXLog.error("Failed preparing share payload")
            return
        }
        
        guard let url = URL(string: "\(InfoPlistReader.main.baseBundleIdentifier):/\(ShareExtensionURLPath)?\(payload)") else {
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
