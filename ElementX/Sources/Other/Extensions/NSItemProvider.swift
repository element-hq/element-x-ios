//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
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
    
    /// Stores the item's data from the provider within the temporary directory, returning the URL on success.
    /// - Parameter withinAppGroupContainer: Whether the data needs to be shared between bundles.
    /// If passing `true` you will need to manually clean up the file once you have the data in the receiving bundle.
    func storeData(withinAppGroupContainer: Bool = false) async -> URL? {
        guard let contentType = preferredContentType else {
            MXLog.error("Invalid NSItemProvider: \(self)")
            return nil
        }
        
        if contentType.type.identifier == UTType.image.identifier {
            return await generateURLForUIImage(contentType, withinAppGroupContainer: withinAppGroupContainer)
        } else {
            return await generateURLForGenericData(contentType, withinAppGroupContainer: withinAppGroupContainer)
        }
    }
    
    private func generateURLForUIImage(_ contentType: PreferredContentType, withinAppGroupContainer: Bool) async -> URL? {
        guard let uiImage = try? await loadItem(forTypeIdentifier: contentType.type.identifier) as? UIImage else {
            MXLog.error("Failed casting UIImage, invalid NSItemProvider: \(self)")
            return nil
        }
        
        let filename = if let suggestedName = suggestedName as NSString?,
                          // Suggestions are nice but their extension is `jpeg`
                          let filename = (suggestedName.deletingPathExtension as NSString).appendingPathExtension(contentType.fileExtension) {
            filename
        } else {
            "\(UUID().uuidString).\(contentType.fileExtension)"
        }
        
        return await Self.writePNGData(of: uiImage,
                                       filename: filename,
                                       withinAppGroupContainer: withinAppGroupContainer,
                                       providerDescription: description)
    }
    
    private func generateURLForGenericData(_ contentType: PreferredContentType, withinAppGroupContainer: Bool) async -> URL? {
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
        
        let filename = if let suggestedName = suggestedName as NSString?,
                          suggestedName.hasPathExtension {
            suggestedName as String
        } else if let suggestedName {
            "\(suggestedName).\(contentType.fileExtension)"
        } else {
            "\(UUID().uuidString).\(contentType.fileExtension)"
        }
        
        return await Self.writeData(shareData,
                                    filename: filename,
                                    withinAppGroupContainer: withinAppGroupContainer,
                                    providerDescription: providerDescription)
    }
    
    // The next 2 methods are static as NSItemProvider isn't Sendable.
    
    @concurrent private static func writePNGData(of image: UIImage,
                                                 filename: String,
                                                 withinAppGroupContainer: Bool,
                                                 providerDescription: String) async -> URL? {
        guard let pngData = image.pngData() else {
            MXLog.error("Failed extracting PNG data out of the UIImage")
            return nil
        }
        
        return await writeData(pngData,
                               filename: filename,
                               withinAppGroupContainer: withinAppGroupContainer,
                               providerDescription: providerDescription)
    }
    
    @concurrent private static func writeData(_ data: Data,
                                              filename: String,
                                              withinAppGroupContainer: Bool,
                                              providerDescription: String) async -> URL? {
        do {
            return try FileManager.default.writeDataToTemporaryDirectory(data: data,
                                                                         fileName: filename,
                                                                         withinAppGroupContainer: withinAppGroupContainer)
        } catch {
            MXLog.error("Failed storing NSItemProvider data \(providerDescription) with error: \(error)")
            return nil
        }
    }
    
    var isSupportedForPasteOrDrop: Bool {
        preferredContentType != nil
    }
    
    var preferredContentType: PreferredContentType? {
        let supportedContentTypes = registeredContentTypes
            .filter { isMimeTypeSupported($0.preferredMIMEType) || isIdentifierSupported($0.identifier) }
        
        // If we can't find any supported types but we do find a fileURL, use
        // the sibling type that provides a correct file extension for it.
        // Return nil otherwise which will make it be inserted into the composer as text.
        guard !supportedContentTypes.isEmpty else {
            guard registeredContentTypes.contains(where: { $0.conforms(to: .fileURL) }) else {
                return nil
            }
            
            for type in registeredContentTypes {
                if let fileExtension = type.preferredFilenameExtension {
                    return .init(type: type, fileExtension: fileExtension)
                }
            }
            
            return nil
        }
        
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
        
        return mimeType.hasPrefix("application/") ||
            mimeType.hasPrefix("audio/") ||
            mimeType.hasPrefix("image/") ||
            mimeType.hasPrefix("video/")
    }
}

extension NSString {
    /// `NSString.pathExtension` returns the trailing dot-segment regardless of whether
    /// it's a real extension, and `UTType(filenameExtension:)` synthesises a `dyn.*`
    /// placeholder for unknown ones instead of returning nil — so check both.
    var hasPathExtension: Bool {
        guard !pathExtension.isEmpty,
              let type = UTType(filenameExtension: pathExtension) else {
            return false
        }
        return !type.isDynamic
    }
}
