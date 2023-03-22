//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

@testable import ElementX
import XCTest

class LocalizationTests: XCTestCase {
    /// Test ElementL10n considers app language changes
    func disabled_testAppLanguage() {
        //  set app language to English
        Bundle.elementLanguage = "en"

        XCTAssertEqual(L10n.actionOk, "OK")
        XCTAssertEqual(L10n.actionContinue, "Continue")
        XCTAssertEqual(L10n.sessionVerificationWaitingToAcceptTitle, "Waiting to accept request")
        XCTAssertEqual(L10n.inviteFriendsText("Element", "element.io"), "Hey, talk to me on Element: element.io")

        //  set app language to Turkish
        Bundle.elementLanguage = "tr"

        XCTAssertEqual(L10n.actionOk, "Tamam")
        XCTAssertEqual(L10n.actionContinue, "Devam et")
        XCTAssertEqual(L10n.sessionVerificationWaitingToAcceptTitle, "Github ile kayıt ol")
        XCTAssertEqual(L10n.inviteFriendsText("Element", "element.io"), "Yalnızca Söz ve Anahtar Kelimeler")
    }

    /// Test fallback language for a language not supported at all
    func disabled_testFallbackOnNotSupportedLanguage() {
        //  set app language to something Element don't support at all (chose 'Malay' language)
        Bundle.elementLanguage = "ms"
        Bundle.elementFallbackLanguage = "en"

        XCTAssertEqual(L10n.actionOk, "OK")
        XCTAssertEqual(L10n.actionContinue, "Continue")
        XCTAssertEqual(L10n.roomTimelineStateChanges(5), "5 room changes")
    }

    /// Test fallback language for a language supported but poorly translated
    func disabled_testFallbackOnNotTranslatedKey() {
        //  set app language to something Element supports but poorly translated (chose 'Sinhala' language)
        Bundle.elementLanguage = "si"
        Bundle.elementFallbackLanguage = "en"

        XCTAssertEqual(L10n.actionOk, "OK")
        XCTAssertEqual(L10n.actionContinue, "Continue")
    }

    /// Test plurals that ElementL10n considers app language changes
    func disabled_testPlurals() {
        //  set app language to English
        Bundle.elementLanguage = "en"

        XCTAssertEqual(L10n.commonMemberCount(1), "1 member")
        XCTAssertEqual(L10n.commonMemberCount(2), "2 members")

        //  set app language to Turkish
        Bundle.elementLanguage = "tr"

        XCTAssertEqual(L10n.commonMemberCount(1), "1 üyelik değişikliği")
        XCTAssertEqual(L10n.commonMemberCount(2), "2 adet üyelik değişikliği")

        //  set app language to Polish
        Bundle.elementLanguage = "pl"

        XCTAssertEqual(L10n.commonMemberCount(1), "1 sekunda") //  one
        XCTAssertEqual(L10n.commonMemberCount(2), "2 sekundy") //  few
        XCTAssertEqual(L10n.commonMemberCount(3), "5 sekund") //  many, other
    }

    /// Test plurals fallback language for a language not supported at all
    func disabled_testPluralsFallbackOnNotSupportedLanguage() {
        //  set app language to something Element don't support at all (chose 'Malay' language)
        Bundle.elementLanguage = "ms"
        Bundle.elementFallbackLanguage = "en"

        XCTAssertEqual(L10n.commonMemberCount(1), "1 member")
        XCTAssertEqual(L10n.commonMemberCount(2), "2 members")
    }

    /// Test plurals fallback language for a language supported but poorly translated
    func disabled_testPluralsFallbackOnNotTranslatedKey() {
        //  set app language to something Element supports but poorly translated (chose 'Sinhala' language)
        Bundle.elementLanguage = "si"
        Bundle.elementFallbackLanguage = "en"

        XCTAssertEqual(L10n.roomTimelineStateChanges(1), "1 room change")
        XCTAssertEqual(L10n.roomTimelineStateChanges(5), "5 room changes")
    }

    /// Test untranslated strings
    func testUntranslated() {
        XCTAssertEqual(UntranslatedL10n.untranslated, "Untranslated")
        XCTAssertEqual(UntranslatedL10n.untranslatedPlural(1), "One untranslated item")
        XCTAssertEqual(UntranslatedL10n.untranslatedPlural(5), "5 untranslated items")
    }
}
