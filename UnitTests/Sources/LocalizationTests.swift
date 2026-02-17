//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@Suite(.serialized)
struct LocalizationTests {
    init() {
        Bundle.overrideLocalizations = nil
    }

    /// Test ElementL10n considers app language changes
    @Test
    func appLanguage() {
        // set app language to English
        Bundle.overrideLocalizations = ["en"]

        #expect(L10n.testLanguageIdentifier == "en")

        // set app language to Italian
        Bundle.overrideLocalizations = ["it"]

        #expect(L10n.testLanguageIdentifier == "it")
    }

    /// Test fallback language for a language not supported at all
    @Test
    func fallbackOnNotSupportedLanguage() {
        //  set app language to something Element don't support at all (chose non existing identifier)
        Bundle.overrideLocalizations = ["xx"]

        #expect(L10n.testLanguageIdentifier == "en")
    }

    /// Test fallback language for a language supported but poorly translated
    @Test
    func fallbackOnNotTranslatedKey() {
        //  set app language to something Element supports but use a key that is not translated (we have a key that should never be translated)
        Bundle.overrideLocalizations = ["it"]

        #expect(L10n.testLanguageIdentifier == "it")
        #expect(L10n.testUntranslatedDefaultLanguageIdentifier == "en")
    }

    /// Test plurals that ElementL10n considers app language changes
    @Test
    func plurals() {
        //  set app language to English
        Bundle.overrideLocalizations = ["en"]

        #expect(L10n.commonMemberCount(1) == "1 Member")
        #expect(L10n.commonMemberCount(2) == "2 Members")

        //  set app language to Italian
        Bundle.overrideLocalizations = ["it"]

        #expect(L10n.commonMemberCount(1) == "1 Membro")
        #expect(L10n.commonMemberCount(2) == "2 Membri")
    }

    /// Test plurals fallback language for a language not supported at all
    @Test
    func pluralsFallbackOnNotSupportedLanguage() {
        //  set app language to something Element don't support at all ("invalid identifier")
        Bundle.overrideLocalizations = ["xx"]

        #expect(L10n.commonMemberCount(1) == "1 Member")
        #expect(L10n.commonMemberCount(2) == "2 Members")
    }

    /// Test untranslated strings
    @Test
    func untranslated() {
        #expect(UntranslatedL10n.untranslated == "Untranslated")
        #expect(UntranslatedL10n.untranslatedPlural(1) == "One untranslated item")
        #expect(UntranslatedL10n.untranslatedPlural(5) == "5 untranslated items")
    }
}
