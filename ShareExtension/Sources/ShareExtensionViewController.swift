//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

class ShareExtensionViewController: UIViewController {
    private let appSettings: CommonSettingsProtocol = AppSettings()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let view = ShareExtensionView()
        
        let hostingController = UIHostingController(rootView: view)
        addChild(hostingController)
        self.view.addSubview(hostingController.view)
        
        NSLayoutConstraint.activate([hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                                     hostingController.view.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                                     hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                                     hostingController.view.rightAnchor.constraint(equalTo: self.view.rightAnchor)])
        
        MXLog.configure(currentTarget: "shareextension", filePrefix: "shareextension", logLevel: appSettings.logLevel)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        processShare()
    }
    
    // MARK: - Private
    
    private func processShare() {
        defer {
            dismiss()
        }
        
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            return
        }
        
        guard let contentType = itemProvider.preferredContentType,
              let preferredExtension = contentType.preferredFilenameExtension else {
            MXLog.error("Invalid NSItemProvider: \(itemProvider)")
            return
        }
        
        Task {
            await openMainApp()
        }
    }
    
    private func openMainApp() async {
        guard let url = URL(string: "\(InfoPlistReader.main.baseBundleIdentifier):/") else {
            return
        }
        
        await openURL(url)
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
