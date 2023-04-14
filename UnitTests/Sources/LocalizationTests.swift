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
    func testAppLanguage() {
        // set app language to English
        Bundle.overrideLocalizations = ["en"]

        XCTAssertEqual(L10n.testLanguageIdentifier, "en")

        // set app language to Italian
        Bundle.overrideLocalizations = ["it"]

        XCTAssertEqual(L10n.testLanguageIdentifier, "it")
    }

    /// Test fallback language for a language not supported at all
    func testFallbackOnNotSupportedLanguage() {
        //  set app language to something Element don't support at all (chose non existing identifier)
        Bundle.overrideLocalizations = ["xx"]

        XCTAssertEqual(L10n.testLanguageIdentifier, "en")
    }

    /// Test fallback language for a language supported but poorly translated
    func testFallbackOnNotTranslatedKey() {
        //  set app language to something Element supports but use a key that is not translated (we have a key that should never be translated)
        Bundle.overrideLocalizations = ["it"]

        XCTAssertEqual(L10n.testLanguageIdentifier, "it")
        XCTAssertEqual(L10n.testUntranslatedDefaultLanguageIdentifier, "en")
    }

    /// Test plurals that ElementL10n considers app language changes
    func testPlurals() {
        //  set app language to English
        Bundle.overrideLocalizations = ["en"]

        XCTAssertEqual(L10n.commonMemberCount(1), "1 member")
        XCTAssertEqual(L10n.commonMemberCount(2), "2 members")

        //  set app language to Italian
        Bundle.overrideLocalizations = ["it"]

        XCTAssertEqual(L10n.commonMemberCount(1), "1 membro")
        XCTAssertEqual(L10n.commonMemberCount(2), "2 membri")

//        //  set app language to Polish
//        Bundle.overrideLocalizations = ["pl"]
//
//        XCTAssertEqual(L10n.commonMemberCount(1), "1 sekunda") //  one
//        XCTAssertEqual(L10n.commonMemberCount(2), "2 sekundy") //  few
//        XCTAssertEqual(L10n.commonMemberCount(3), "5 sekund") //  many, other
    }

    /// Test plurals fallback language for a language not supported at all
    func testPluralsFallbackOnNotSupportedLanguage() {
        //  set app language to something Element don't support at all ("invalid identifier")
        Bundle.overrideLocalizations = ["xx"]

        XCTAssertEqual(L10n.commonMemberCount(1), "1 member")
        XCTAssertEqual(L10n.commonMemberCount(2), "2 members")
    }

    /// Test untranslated strings
    func testUntranslated() {
        XCTAssertEqual(UntranslatedL10n.untranslated, "Untranslated")
        XCTAssertEqual(UntranslatedL10n.untranslatedPlural(1), "One untranslated item")
        XCTAssertEqual(UntranslatedL10n.untranslatedPlural(5), "5 untranslated items")
    }
}
