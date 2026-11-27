//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing
import UniformTypeIdentifiers

struct NSItemProviderTests {
    // MARK: - hasPathExtension
    
    @Test("Registered file extensions are recognised")
    func registeredExtensions() {
        #expect(("IMG_1234.jpg" as NSString).hasPathExtension)
        #expect(("photo.png" as NSString).hasPathExtension)
        #expect(("clip.heic" as NSString).hasPathExtension)
        #expect(("doc.pdf" as NSString).hasPathExtension)
    }
    
    @Test("Date-like trailing segments aren't treated as extensions")
    func dateLikeTrailingSegments() {
        // iOS screenshot drags expose a `suggestedName` like
        // `Screenshot 2026-05-22 at 14.49.40`, whose `pathExtension` is `"40"`.
        // `UTType(filenameExtension:)` synthesises a `dyn.*` placeholder for that —
        // it must not be treated as a real extension.
        #expect(!("Screenshot 2026-05-22 at 14.49.40" as NSString).hasPathExtension)
        #expect(!("report 2025.10" as NSString).hasPathExtension)
        #expect(!("v1.2.3" as NSString).hasPathExtension)
    }
    
    @Test("Names without an extension are rejected")
    func absentExtension() {
        #expect(!("plainname" as NSString).hasPathExtension)
        #expect(!("" as NSString).hasPathExtension)
        #expect(!("trailing dot." as NSString).hasPathExtension)
    }
    
    // MARK: - storeData()
    
    @Test("The extension is appended when the suggested name looks like a screenshot")
    func screenshotSuggestedName() async throws {
        let provider = try makeImageProvider()
        provider.suggestedName = "Screenshot 2026-05-22 at 14.49.40"
        
        let storedURL = try #require(await provider.storeData())
        
        #expect(storedURL.pathExtension == "png")
        #expect(storedURL.deletingPathExtension().lastPathComponent == "Screenshot 2026-05-22 at 14.49.40")
    }
    
    @Test("A suggested name with a real extension is kept")
    func suggestedNameWithExtension() async throws {
        let provider = try makeImageProvider()
        provider.suggestedName = "IMG_1234.png"
        
        let storedURL = try #require(await provider.storeData())
        
        #expect(storedURL.lastPathComponent == "IMG_1234.png")
    }
    
    @Test("The original file name is kept when the provider has no suggested name")
    func originalFileName() async throws {
        let provider = try makeImageProvider()
        provider.suggestedName = nil
        
        let storedURL = try #require(await provider.storeData())
        
        #expect(storedURL.lastPathComponent == "test_image.png")
    }
    
    @Test("Data-only providers without a name fall back to a generated one with the content type's extension")
    func dataOnlyProvider() async throws {
        let data = Data("%PDF-1.4".utf8)
        let provider = NSItemProvider(item: data as NSData, typeIdentifier: UTType.pdf.identifier)
        
        let storedURL = try #require(await provider.storeData())
        
        #expect(storedURL.pathExtension == "pdf")
        #expect(try Data(contentsOf: storedURL) == data)
    }
    
    @Test("An empty suggested name falls back to the original file name")
    func emptySuggestedName() async throws {
        let provider = try makeImageProvider()
        provider.suggestedName = ""
        
        let storedURL = try #require(await provider.storeData())
        
        #expect(storedURL.lastPathComponent == "test_image.png")
    }
    
    @Test("A name whose extension doesn't match the loaded type gets the type's extension")
    func mismatchedExtension() async throws {
        let provider = try makeImageProvider()
        provider.suggestedName = "IMG_0001.HEIC"
        
        let storedURL = try #require(await provider.storeData())
        
        #expect(storedURL.lastPathComponent == "IMG_0001.png")
    }
    
    @Test("Slashes in a name are replaced so it stays a single file name")
    func slashInName() async throws {
        let provider = try makeImageProvider()
        provider.suggestedName = "Element / Matrix.png"
        
        let storedURL = try #require(await provider.storeData())
        
        #expect(storedURL.lastPathComponent == "Element - Matrix.png")
        #expect(FileManager.default.fileExists(atPath: storedURL.path(percentEncoded: false)))
    }
    
    // MARK: - Helpers
    
    private func makeImageProvider() throws -> NSItemProvider {
        let imageURL = try #require(Bundle(for: BundleAnchor.self).url(forResource: "test_image.png", withExtension: nil),
                                    "Failed retrieving fixture")
        return try #require(NSItemProvider(contentsOf: imageURL), "Failed creating the item provider")
    }
}

/// `Bundle(for:)` requires a class; the enclosing test type is a struct, so we keep
/// a private anchor to scope the lookup to the unit test bundle.
private final class BundleAnchor { }
