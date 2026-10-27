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

final class LocalizationTests {
    deinit {
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
    
    /// Test SAS emoji descriptions are looked up by their index in the spec's emoji table
    @Test
    func sasEmojiDescriptions() {
        Bundle.overrideLocalizations = ["de"]
        
        #expect(SessionVerificationEmoji(index: 0, symbol: "🐶", description: "Dog").localizedDescription == "Hund")
        #expect(SessionVerificationEmoji(index: 36, symbol: "👍", description: "Thumbs Up").localizedDescription == "Daumen Hoch")
        #expect(SessionVerificationEmoji(index: 41, symbol: "💡", description: "Light Bulb").localizedDescription == "Glühbirne")
        
        Bundle.overrideLocalizations = ["hr"]
        
        #expect(SessionVerificationEmoji(index: 23, symbol: "🍌", description: "Banana").localizedDescription == "banana")
    }
    
    /// Test every emoji in the spec's SAS emoji table has a description
    @Test
    func sasEmojiTableIsComplete() {
        Bundle.overrideLocalizations = ["en"]
        
        for index in 0..<64 {
            #expect(SASL10n.localizedDescription(for: index) != nil)
        }
    }
    
    /// Test SAS emoji fall back to the SDK's description when they have no translation
    @Test
    func sasEmojiDescriptionFallback() {
        #expect(SessionVerificationEmoji(index: 64, symbol: "❓", description: "Unknown").localizedDescription == "Unknown")
    }
    
    /// Test untranslated strings
    @Test
    func untranslated() {
        #expect(UntranslatedL10n.untranslated == "Untranslated")
        #expect(UntranslatedL10n.untranslatedPlural(1) == "One untranslated item")
        #expect(UntranslatedL10n.untranslatedPlural(5) == "5 untranslated items")
    }
}
