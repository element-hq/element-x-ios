//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension NSItemProvider {
    struct PreferredContentType {
        let type: UTType
        let fileExtension: String
    }
    
    func loadTransferable<T: Transferable>(type transferableType: T.Type) async -> T? {
        try? await withCheckedContinuation { continuation in
            _ = loadTransferable(type: T.self) { result in
                continuation.resume(returning: result)
            }
        }
        .get()
    }
    
    func loadString() async -> String? {
        try? await loadItem(forTypeIdentifier: UTType.text.identifier) as? String
    }
    
    func storeData() async -> URL? {
        guard let contentType = preferredContentType else {
            MXLog.error("Invalid NSItemProvider: \(self)")
            return nil
        }
        
        if contentType.type.identifier == UTType.image.identifier {
            return await generateURLForUIImage(contentType)
        } else {
            return await generateURLForGenericData(contentType)
        }
    }
    
    private func generateURLForUIImage(_ contentType: PreferredContentType) async -> URL? {
        guard let uiImage = try? await loadItem(forTypeIdentifier: contentType.type.identifier) as? UIImage else {
            MXLog.error("Failed casting UIImage, invalid NSItemProvider: \(self)")
            return nil
        }
        
        guard let pngData = uiImage.pngData() else {
            MXLog.error("Failed extracting PNG data out of the UIImage")
            return nil
        }
        
        do {
            if let suggestedName = suggestedName as? NSString,
               // Suggestions are nice but their extension is `jpeg`
               let filename = (suggestedName.deletingPathExtension as NSString).appendingPathExtension(contentType.fileExtension) {
                return try FileManager.default.writeDataToTemporaryDirectory(data: pngData, fileName: filename)
            } else {
                let filename = "\(UUID().uuidString).\(contentType.fileExtension)"
                return try FileManager.default.writeDataToTemporaryDirectory(data: pngData, fileName: filename)
            }
        } catch {
            MXLog.error("Failed storing NSItemProvider data \(self) with error: \(error)")
            return nil
        }
    }
    
    private func generateURLForGenericData(_ contentType: PreferredContentType) async -> URL? {
        let providerDescription = description
        let shareData: Data? = await withCheckedContinuation { continuation in
            _ = loadDataRepresentation(for: contentType.type) { data, error in
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
            MXLog.error("Invalid share data")
            return nil
        }
        
        do {
            if let filename = suggestedName {
                let hasExtension = !(filename as NSString).pathExtension.isEmpty
                let filename = hasExtension ? filename : "\(filename).\(contentType.fileExtension)"
                return try FileManager.default.writeDataToTemporaryDirectory(data: shareData, fileName: filename)
            } else {
                let filename = "\(UUID().uuidString).\(contentType.fileExtension)"
                return try FileManager.default.writeDataToTemporaryDirectory(data: shareData, fileName: filename)
            }
        } catch {
            MXLog.error("Failed storing NSItemProvider data \(self) with error: \(error)")
            return nil
        }
    }
    
    var isSupportedForPasteOrDrop: Bool {
        preferredContentType != nil
    }
    
    var preferredContentType: PreferredContentType? {
        let supportedContentTypes = registeredContentTypes
            .filter { isMimeTypeSupported($0.preferredMIMEType) || isIdentifierSupported($0.identifier) }
        
        // Have .jpeg take priority over .heic
        if supportedContentTypes.contains(.jpeg) {
            guard let fileExtension = preferredFileExtension(for: .jpeg) else {
                return nil
            }
            
            return .init(type: .jpeg, fileExtension: fileExtension)
        }
        
        guard let preferredContentType = supportedContentTypes.first,
              let fileExtension = preferredFileExtension(for: preferredContentType) else {
            return nil
        }
        
        return .init(type: preferredContentType, fileExtension: fileExtension)
    }
    
    private func preferredFileExtension(for contentType: UTType) -> String? {
        if let fileExtension = contentType.preferredFilenameExtension {
            return fileExtension
        }
        
        switch contentType.identifier {
        case UTType.image.identifier:
            return "png"
        default:
            return nil
        }
    }
    
    private func isIdentifierSupported(_ identifier: String?) -> Bool {
        // Don't filter out generic public.image content as screenshots are in this format
        // and we can convert them to a PNG ourselves.
        identifier == UTType.image.identifier
    }
    
    private func isMimeTypeSupported(_ mimeType: String?) -> Bool {
        guard let mimeType else {
            return false
        }
        
        // Prevents media upload triggering for text copied from Notes.app #1247
        if mimeType == "application/x-webarchive" {
            return false
        }
        
        return mimeType.hasPrefix("image/") || mimeType.hasPrefix("video/") || mimeType.hasPrefix("application/")
    }
}
