//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct Country: Identifiable, Equatable, Hashable {
    let isoCode: String // ISO 3166-1 alpha-2, e.g. "US"
    let dialCode: String // E.164 calling code digits, e.g. "1"

    var id: String { isoCode }

    var name: String {
        Locale.current.localizedString(forRegionCode: isoCode) ?? isoCode
    }

    var flag: String {
        let base: UInt32 = 0x1F1E6 - 0x41 // Regional Indicator Symbol "A" - ASCII "A"
        var result = ""
        for scalar in isoCode.uppercased().unicodeScalars {
            if let s = Unicode.Scalar(base + scalar.value) {
                result.unicodeScalars.append(s)
            }
        }
        return result
    }

    /// National-format example mobile number for the country, used as the input placeholder
    /// (e.g. US "555 123 4567", BR "11 91234 5678"). Falls back to a generic 10-digit hint.
    var nationalExample: String {
        Country.nationalExamples[isoCode] ?? "123 456 7890"
    }
    
    /// Formats the user-typed local digits according to the country's preferred mask, e.g.
    /// `"51985550619"` → `"(51) 98555-0619"` (BR) or `"5551234567"` → `"(555) 123-4567"` (US).
    /// Extra digits past the mask are appended unformatted. Returns the raw digits unchanged
    /// when no mask is defined for the country.
    func formatNational(digits rawDigits: String) -> String {
        let digits = rawDigits.filter(\.isNumber)
        guard !digits.isEmpty else { return "" }
        let mask = Country.nationalMasks[isoCode] ?? Country.deriveMask(from: nationalExample)
        var result = ""
        var digitIndex = digits.startIndex
        for ch in mask {
            if digitIndex == digits.endIndex { break }
            if ch == "#" {
                result.append(digits[digitIndex])
                digitIndex = digits.index(after: digitIndex)
            } else {
                result.append(ch)
            }
        }
        if digitIndex < digits.endIndex {
            result.append(contentsOf: digits[digitIndex...])
        }
        return result
    }
}

extension Country {
    /// Resolves the user's country from device locale, falling back to US.
    static var deviceDefault: Country {
        let region = Locale.current.region?.identifier
            ?? Locale.current.regionCode
            ?? "US"
        return all.first { $0.isoCode == region.uppercased() } ?? fallback
    }

    static let fallback = Country(isoCode: "US", dialCode: "1")

    /// Looks up a country by its ISO code (case-insensitive).
    static func find(isoCode: String) -> Country? {
        all.first { $0.isoCode == isoCode.uppercased() }
    }

    /// Best-effort match by dial code. When several countries share a code (e.g. +1)
    /// the first entry in `all` wins — typically the most populous one.
    static func find(dialCode: String) -> Country? {
        let trimmed = dialCode.trimmingCharacters(in: CharacterSet(charactersIn: "+ "))
        return all.first { $0.dialCode == trimmed }
    }

    /// ISO 3166-1 alpha-2 + ITU-T E.164 dial code. Hand-curated; the order matters
    /// only for `find(dialCode:)` ambiguity (most populous listed first).
    static let all: [Country] = [
        Country(isoCode: "US", dialCode: "1"),
        Country(isoCode: "CA", dialCode: "1"),
        Country(isoCode: "GB", dialCode: "44"),
        Country(isoCode: "AF", dialCode: "93"),
        Country(isoCode: "AL", dialCode: "355"),
        Country(isoCode: "DZ", dialCode: "213"),
        Country(isoCode: "AS", dialCode: "1684"),
        Country(isoCode: "AD", dialCode: "376"),
        Country(isoCode: "AO", dialCode: "244"),
        Country(isoCode: "AI", dialCode: "1264"),
        Country(isoCode: "AG", dialCode: "1268"),
        Country(isoCode: "AR", dialCode: "54"),
        Country(isoCode: "AM", dialCode: "374"),
        Country(isoCode: "AW", dialCode: "297"),
        Country(isoCode: "AU", dialCode: "61"),
        Country(isoCode: "AT", dialCode: "43"),
        Country(isoCode: "AZ", dialCode: "994"),
        Country(isoCode: "BS", dialCode: "1242"),
        Country(isoCode: "BH", dialCode: "973"),
        Country(isoCode: "BD", dialCode: "880"),
        Country(isoCode: "BB", dialCode: "1246"),
        Country(isoCode: "BY", dialCode: "375"),
        Country(isoCode: "BE", dialCode: "32"),
        Country(isoCode: "BZ", dialCode: "501"),
        Country(isoCode: "BJ", dialCode: "229"),
        Country(isoCode: "BM", dialCode: "1441"),
        Country(isoCode: "BT", dialCode: "975"),
        Country(isoCode: "BO", dialCode: "591"),
        Country(isoCode: "BA", dialCode: "387"),
        Country(isoCode: "BW", dialCode: "267"),
        Country(isoCode: "BR", dialCode: "55"),
        Country(isoCode: "IO", dialCode: "246"),
        Country(isoCode: "VG", dialCode: "1284"),
        Country(isoCode: "BN", dialCode: "673"),
        Country(isoCode: "BG", dialCode: "359"),
        Country(isoCode: "BF", dialCode: "226"),
        Country(isoCode: "BI", dialCode: "257"),
        Country(isoCode: "KH", dialCode: "855"),
        Country(isoCode: "CM", dialCode: "237"),
        Country(isoCode: "CV", dialCode: "238"),
        Country(isoCode: "KY", dialCode: "1345"),
        Country(isoCode: "CF", dialCode: "236"),
        Country(isoCode: "TD", dialCode: "235"),
        Country(isoCode: "CL", dialCode: "56"),
        Country(isoCode: "CN", dialCode: "86"),
        Country(isoCode: "CX", dialCode: "61"),
        Country(isoCode: "CC", dialCode: "61"),
        Country(isoCode: "CO", dialCode: "57"),
        Country(isoCode: "KM", dialCode: "269"),
        Country(isoCode: "CK", dialCode: "682"),
        Country(isoCode: "CR", dialCode: "506"),
        Country(isoCode: "HR", dialCode: "385"),
        Country(isoCode: "CU", dialCode: "53"),
        Country(isoCode: "CW", dialCode: "599"),
        Country(isoCode: "CY", dialCode: "357"),
        Country(isoCode: "CZ", dialCode: "420"),
        Country(isoCode: "CD", dialCode: "243"),
        Country(isoCode: "DK", dialCode: "45"),
        Country(isoCode: "DJ", dialCode: "253"),
        Country(isoCode: "DM", dialCode: "1767"),
        Country(isoCode: "DO", dialCode: "1809"),
        Country(isoCode: "EC", dialCode: "593"),
        Country(isoCode: "EG", dialCode: "20"),
        Country(isoCode: "SV", dialCode: "503"),
        Country(isoCode: "GQ", dialCode: "240"),
        Country(isoCode: "ER", dialCode: "291"),
        Country(isoCode: "EE", dialCode: "372"),
        Country(isoCode: "ET", dialCode: "251"),
        Country(isoCode: "FK", dialCode: "500"),
        Country(isoCode: "FO", dialCode: "298"),
        Country(isoCode: "FJ", dialCode: "679"),
        Country(isoCode: "FI", dialCode: "358"),
        Country(isoCode: "FR", dialCode: "33"),
        Country(isoCode: "PF", dialCode: "689"),
        Country(isoCode: "GA", dialCode: "241"),
        Country(isoCode: "GM", dialCode: "220"),
        Country(isoCode: "GE", dialCode: "995"),
        Country(isoCode: "DE", dialCode: "49"),
        Country(isoCode: "GH", dialCode: "233"),
        Country(isoCode: "GI", dialCode: "350"),
        Country(isoCode: "GR", dialCode: "30"),
        Country(isoCode: "GL", dialCode: "299"),
        Country(isoCode: "GD", dialCode: "1473"),
        Country(isoCode: "GU", dialCode: "1671"),
        Country(isoCode: "GT", dialCode: "502"),
        Country(isoCode: "GG", dialCode: "44"),
        Country(isoCode: "GN", dialCode: "224"),
        Country(isoCode: "GW", dialCode: "245"),
        Country(isoCode: "GY", dialCode: "592"),
        Country(isoCode: "HT", dialCode: "509"),
        Country(isoCode: "HN", dialCode: "504"),
        Country(isoCode: "HK", dialCode: "852"),
        Country(isoCode: "HU", dialCode: "36"),
        Country(isoCode: "IS", dialCode: "354"),
        Country(isoCode: "IN", dialCode: "91"),
        Country(isoCode: "ID", dialCode: "62"),
        Country(isoCode: "IR", dialCode: "98"),
        Country(isoCode: "IQ", dialCode: "964"),
        Country(isoCode: "IE", dialCode: "353"),
        Country(isoCode: "IM", dialCode: "44"),
        Country(isoCode: "IL", dialCode: "972"),
        Country(isoCode: "IT", dialCode: "39"),
        Country(isoCode: "CI", dialCode: "225"),
        Country(isoCode: "JM", dialCode: "1876"),
        Country(isoCode: "JP", dialCode: "81"),
        Country(isoCode: "JE", dialCode: "44"),
        Country(isoCode: "JO", dialCode: "962"),
        Country(isoCode: "KZ", dialCode: "7"),
        Country(isoCode: "KE", dialCode: "254"),
        Country(isoCode: "KI", dialCode: "686"),
        Country(isoCode: "XK", dialCode: "383"),
        Country(isoCode: "KW", dialCode: "965"),
        Country(isoCode: "KG", dialCode: "996"),
        Country(isoCode: "LA", dialCode: "856"),
        Country(isoCode: "LV", dialCode: "371"),
        Country(isoCode: "LB", dialCode: "961"),
        Country(isoCode: "LS", dialCode: "266"),
        Country(isoCode: "LR", dialCode: "231"),
        Country(isoCode: "LY", dialCode: "218"),
        Country(isoCode: "LI", dialCode: "423"),
        Country(isoCode: "LT", dialCode: "370"),
        Country(isoCode: "LU", dialCode: "352"),
        Country(isoCode: "MO", dialCode: "853"),
        Country(isoCode: "MK", dialCode: "389"),
        Country(isoCode: "MG", dialCode: "261"),
        Country(isoCode: "MW", dialCode: "265"),
        Country(isoCode: "MY", dialCode: "60"),
        Country(isoCode: "MV", dialCode: "960"),
        Country(isoCode: "ML", dialCode: "223"),
        Country(isoCode: "MT", dialCode: "356"),
        Country(isoCode: "MH", dialCode: "692"),
        Country(isoCode: "MR", dialCode: "222"),
        Country(isoCode: "MU", dialCode: "230"),
        Country(isoCode: "YT", dialCode: "262"),
        Country(isoCode: "MX", dialCode: "52"),
        Country(isoCode: "FM", dialCode: "691"),
        Country(isoCode: "MD", dialCode: "373"),
        Country(isoCode: "MC", dialCode: "377"),
        Country(isoCode: "MN", dialCode: "976"),
        Country(isoCode: "ME", dialCode: "382"),
        Country(isoCode: "MS", dialCode: "1664"),
        Country(isoCode: "MA", dialCode: "212"),
        Country(isoCode: "MZ", dialCode: "258"),
        Country(isoCode: "MM", dialCode: "95"),
        Country(isoCode: "NA", dialCode: "264"),
        Country(isoCode: "NR", dialCode: "674"),
        Country(isoCode: "NP", dialCode: "977"),
        Country(isoCode: "NL", dialCode: "31"),
        Country(isoCode: "NC", dialCode: "687"),
        Country(isoCode: "NZ", dialCode: "64"),
        Country(isoCode: "NI", dialCode: "505"),
        Country(isoCode: "NE", dialCode: "227"),
        Country(isoCode: "NG", dialCode: "234"),
        Country(isoCode: "NU", dialCode: "683"),
        Country(isoCode: "KP", dialCode: "850"),
        Country(isoCode: "MP", dialCode: "1670"),
        Country(isoCode: "NO", dialCode: "47"),
        Country(isoCode: "OM", dialCode: "968"),
        Country(isoCode: "PK", dialCode: "92"),
        Country(isoCode: "PW", dialCode: "680"),
        Country(isoCode: "PS", dialCode: "970"),
        Country(isoCode: "PA", dialCode: "507"),
        Country(isoCode: "PG", dialCode: "675"),
        Country(isoCode: "PY", dialCode: "595"),
        Country(isoCode: "PE", dialCode: "51"),
        Country(isoCode: "PH", dialCode: "63"),
        Country(isoCode: "PL", dialCode: "48"),
        Country(isoCode: "PT", dialCode: "351"),
        Country(isoCode: "PR", dialCode: "1787"),
        Country(isoCode: "QA", dialCode: "974"),
        Country(isoCode: "CG", dialCode: "242"),
        Country(isoCode: "RE", dialCode: "262"),
        Country(isoCode: "RO", dialCode: "40"),
        Country(isoCode: "RU", dialCode: "7"),
        Country(isoCode: "RW", dialCode: "250"),
        Country(isoCode: "BL", dialCode: "590"),
        Country(isoCode: "SH", dialCode: "290"),
        Country(isoCode: "KN", dialCode: "1869"),
        Country(isoCode: "LC", dialCode: "1758"),
        Country(isoCode: "MF", dialCode: "590"),
        Country(isoCode: "PM", dialCode: "508"),
        Country(isoCode: "VC", dialCode: "1784"),
        Country(isoCode: "WS", dialCode: "685"),
        Country(isoCode: "SM", dialCode: "378"),
        Country(isoCode: "ST", dialCode: "239"),
        Country(isoCode: "SA", dialCode: "966"),
        Country(isoCode: "SN", dialCode: "221"),
        Country(isoCode: "RS", dialCode: "381"),
        Country(isoCode: "SC", dialCode: "248"),
        Country(isoCode: "SL", dialCode: "232"),
        Country(isoCode: "SG", dialCode: "65"),
        Country(isoCode: "SX", dialCode: "1721"),
        Country(isoCode: "SK", dialCode: "421"),
        Country(isoCode: "SI", dialCode: "386"),
        Country(isoCode: "SB", dialCode: "677"),
        Country(isoCode: "SO", dialCode: "252"),
        Country(isoCode: "ZA", dialCode: "27"),
        Country(isoCode: "KR", dialCode: "82"),
        Country(isoCode: "SS", dialCode: "211"),
        Country(isoCode: "ES", dialCode: "34"),
        Country(isoCode: "LK", dialCode: "94"),
        Country(isoCode: "SD", dialCode: "249"),
        Country(isoCode: "SR", dialCode: "597"),
        Country(isoCode: "SZ", dialCode: "268"),
        Country(isoCode: "SE", dialCode: "46"),
        Country(isoCode: "CH", dialCode: "41"),
        Country(isoCode: "SY", dialCode: "963"),
        Country(isoCode: "TW", dialCode: "886"),
        Country(isoCode: "TJ", dialCode: "992"),
        Country(isoCode: "TZ", dialCode: "255"),
        Country(isoCode: "TH", dialCode: "66"),
        Country(isoCode: "TL", dialCode: "670"),
        Country(isoCode: "TG", dialCode: "228"),
        Country(isoCode: "TK", dialCode: "690"),
        Country(isoCode: "TO", dialCode: "676"),
        Country(isoCode: "TT", dialCode: "1868"),
        Country(isoCode: "TN", dialCode: "216"),
        Country(isoCode: "TR", dialCode: "90"),
        Country(isoCode: "TM", dialCode: "993"),
        Country(isoCode: "TC", dialCode: "1649"),
        Country(isoCode: "TV", dialCode: "688"),
        Country(isoCode: "VI", dialCode: "1340"),
        Country(isoCode: "UG", dialCode: "256"),
        Country(isoCode: "UA", dialCode: "380"),
        Country(isoCode: "AE", dialCode: "971"),
        Country(isoCode: "UY", dialCode: "598"),
        Country(isoCode: "UZ", dialCode: "998"),
        Country(isoCode: "VU", dialCode: "678"),
        Country(isoCode: "VA", dialCode: "39"),
        Country(isoCode: "VE", dialCode: "58"),
        Country(isoCode: "VN", dialCode: "84"),
        Country(isoCode: "WF", dialCode: "681"),
        Country(isoCode: "YE", dialCode: "967"),
        Country(isoCode: "ZM", dialCode: "260"),
        Country(isoCode: "ZW", dialCode: "263")
    ]

    // MARK: - Smart detection

    /// NANP area codes (NPA) assigned to Canada. The North American Numbering Plan
    /// shares the +1 dial code between the US, Canada and most Caribbean nations.
    /// Caribbean countries are disambiguated by full +1XXX dial codes in `all`;
    /// Canada vs US must be disambiguated by the local 3-digit area code.
    /// Source: Canadian Numbering Administrator (CNA), 2024.
    static let canadianAreaCodes: Set<String> = [
        "204", "226", "236", "249", "250", "263", "289", "306", "343", "354",
        "365", "367", "368", "382", "387", "403", "416", "418", "428", "431",
        "437", "438", "450", "468", "474", "506", "514", "519", "548", "568",
        "579", "581", "584", "587", "600", "604", "613", "622", "633", "639",
        "644", "647", "655", "672", "683", "705", "709", "742", "753", "778",
        "780", "782", "807", "819", "825", "833", "867", "873", "879", "902", "905"
    ]

    /// Picks the most likely country for the digits the user is currently typing,
    /// given their currently selected country. Returns `nil` if the current
    /// selection is already the best match.
    ///
    /// Rules:
    /// 1. **Longest-prefix dial code match** against `all`. Handles e.g. user typing
    ///    "242" while on US (+1) — recognises Bahamas (+1242). Also handles users
    ///    pasting their full local number starting with a country code.
    /// 2. **NANP +1 disambiguation**: when the dial code is "1" and ≥3 local digits
    ///    are entered, look up the area code in `canadianAreaCodes` to flip between
    ///    US and Canada.
    static func detect(localDigits: String, current: Country) -> Country? {
        let combined = current.dialCode + localDigits

        // Longest-prefix match (4 → 2 digits), skipping anything equal to the current dial code.
        let maxLen = min(5, combined.count)
        if maxLen >= 2 {
            for length in stride(from: maxLen, through: 2, by: -1) {
                let prefix = String(combined.prefix(length))
                if prefix == current.dialCode { continue }
                if let match = all.first(where: { $0.dialCode == prefix }), match != current {
                    return match
                }
            }
        }

        // NANP: US ↔ Canada area-code disambiguation.
        if current.dialCode == "1", localDigits.count >= 3 {
            let area = String(localDigits.prefix(3))
            let isCanadian = canadianAreaCodes.contains(area)
            if isCanadian, current.isoCode != "CA" {
                return find(isoCode: "CA")
            }
            if !isCanadian, current.isoCode == "CA" {
                return find(isoCode: "US")
            }
        }

        return nil
    }
}

private extension Country {
    /// National-format example mobile numbers (no country code). Used as input placeholder.
    /// Curated for the most-populous markets; everything else falls back to a 10-digit generic.
    static let nationalExamples: [String: String] = [
        "US": "555 123 4567",
        "CA": "506 555 0123",
        "BR": "11 91234 5678",
        "PT": "912 345 678",
        "MX": "55 1234 5678",
        "AR": "11 1234 5678",
        "CL": "9 1234 5678",
        "CO": "300 1234567",
        "PE": "912 345 678",
        "GB": "07700 900123",
        "IE": "085 012 3456",
        "DE": "0151 12345678",
        "FR": "06 12 34 56 78",
        "ES": "612 34 56 78",
        "IT": "312 345 6789",
        "NL": "06 12345678",
        "BE": "0470 12 34 56",
        "CH": "078 123 45 67",
        "AT": "0664 1234567",
        "SE": "070-123 45 67",
        "NO": "406 12 345",
        "DK": "20 12 34 56",
        "FI": "041 2345678",
        "PL": "512 345 678",
        "CZ": "601 123 456",
        "GR": "691 234 5678",
        "RO": "0712 345 678",
        "TR": "0532 123 45 67",
        "UA": "050 123 4567",
        "RU": "912 345-67-89",
        "IN": "81234 56789",
        "PK": "0301 2345678",
        "BD": "01712 345678",
        "ID": "0812 3456 7890",
        "PH": "0917 123 4567",
        "VN": "091 234 56 78",
        "TH": "081 234 5678",
        "MY": "012 345 6789",
        "SG": "8123 4567",
        "JP": "090 1234 5678",
        "KR": "010 1234 5678",
        "CN": "131 2345 6789",
        "HK": "5123 4567",
        "TW": "0912 345 678",
        "AU": "0412 345 678",
        "NZ": "021 123 4567",
        "ZA": "071 123 4567",
        "NG": "0802 123 4567",
        "KE": "0712 345 678",
        "EG": "0100 123 4567",
        "MA": "06 12 34 56 78",
        "DZ": "0551 23 45 67",
        "AE": "050 123 4567",
        "SA": "051 234 5678",
        "IL": "050 123 4567",
        "QA": "5012 3456",
        "KW": "501 23456",
        "LB": "03 123 456"
    ]
    
    /// Live-formatting masks per country. `#` is a digit placeholder; everything else is a
    /// literal separator inserted as the user types. Curated for markets where the local
    /// convention groups digits with parens/dashes; otherwise `deriveMask` infers a mask
    /// from `nationalExamples`.
    static let nationalMasks: [String: String] = [
        "US": "(###) ###-####",
        "CA": "(###) ###-####",
        "BR": "(##) #####-####"
    ]
    
    /// Replaces every digit in `example` with `#`, preserving the separators. Used when no
    /// explicit `nationalMasks` entry exists for the country.
    static func deriveMask(from example: String) -> String {
        String(example.map { $0.isNumber ? "#" : $0 })
    }
}
