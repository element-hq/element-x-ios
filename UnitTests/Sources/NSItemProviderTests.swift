//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

struct NSItemProviderTests {
    // MARK: - hasPathExtension

    @Test
    func hasPathExtensionRecognisesRegisteredExtensions() {
        #expect(("IMG_1234.jpg" as NSString).hasPathExtension)
        #expect(("photo.png" as NSString).hasPathExtension)
        #expect(("clip.heic" as NSString).hasPathExtension)
        #expect(("doc.pdf" as NSString).hasPathExtension)
    }

    @Test
    func hasPathExtensionRejectsDateLikeTrailingSegments() {
        // iOS screenshot drags expose a `suggestedName` like
        // `Screenshot 2026-05-22 at 14.49.40`, whose `pathExtension` is `"40"`.
        // `UTType(filenameExtension:)` synthesises a `dyn.*` placeholder for that —
        // it must not be treated as a real extension.
        #expect(!("Screenshot 2026-05-22 at 14.49.40" as NSString).hasPathExtension)
        #expect(!("report 2025.10" as NSString).hasPathExtension)
        #expect(!("v1.2.3" as NSString).hasPathExtension)
    }

    @Test
    func hasPathExtensionRejectsAbsentExtension() {
        #expect(!("plainname" as NSString).hasPathExtension)
        #expect(!("" as NSString).hasPathExtension)
        #expect(!("trailing dot." as NSString).hasPathExtension)
    }

    // MARK: - storeData()

    @Test
    func storeDataAppendsExtensionWhenSuggestedNameLooksLikeAScreenshot() async throws {
        let imageURL = try #require(Bundle(for: BundleAnchor.self).url(forResource: "test_image.png", withExtension: nil),
                                    "Failed retrieving fixture")
        let provider = try #require(NSItemProvider(contentsOf: imageURL))
        provider.suggestedName = "Screenshot 2026-05-22 at 14.49.40"

        let storedURL = try #require(await provider.storeData())

        #expect(storedURL.pathExtension == "png")
        #expect(storedURL.deletingPathExtension().lastPathComponent == "Screenshot 2026-05-22 at 14.49.40")
    }

    @Test
    func storeDataPreservesSuggestedNameWithRealExtension() async throws {
        let imageURL = try #require(Bundle(for: BundleAnchor.self).url(forResource: "test_image.png", withExtension: nil),
                                    "Failed retrieving fixture")
        let provider = try #require(NSItemProvider(contentsOf: imageURL))
        provider.suggestedName = "IMG_1234.png"

        let storedURL = try #require(await provider.storeData())

        #expect(storedURL.lastPathComponent == "IMG_1234.png")
    }
}

/// `Bundle(for:)` requires a class; the enclosing test type is a struct, so we keep
/// a private anchor to scope the lookup to the unit test bundle.
private final class BundleAnchor { }
