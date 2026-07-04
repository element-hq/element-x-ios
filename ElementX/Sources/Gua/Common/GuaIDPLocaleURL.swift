//
// Copyright 2025 Gua
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension URLComponents {
    /// Appends a `ui_locales` query parameter for the current device language so the IDP (MAS)
    /// renders in the user's language, **without disturbing the percent-encoding of the query
    /// that is already present**.
    ///
    /// Why not `queryItems.append(...)`: assigning through `URLComponents.queryItems` re-serializes
    /// the whole query and, in doing so, decodes an already-encoded `%2B` back to a bare `+`. A
    /// bare `+` in a query value is `application/x-www-form-urlencoded` shorthand for a space, so
    /// the downstream `login_hint=%2B<E.164>` that the SDK produced would arrive at MAS / idp-web as
    /// `login_hint=<space><digits>` — no longer a valid E.164. idp-web then fails to pre-fill and
    /// re-prompts for the phone number instead of jumping straight to the OTP step. Appending to the
    /// raw `percentEncodedQuery` string leaves the existing `%2B` (and every other escape) untouched.
    mutating func appendUILocalesPreservingEncoding(languageCode: String? = Locale.current.language.languageCode?.identifier) {
        guard let languageCode, !languageCode.isEmpty else { return }

        // Encode the locale as a query-value: never emit a bare `+`, `&`, or `=` that would be
        // misread. Language codes are ASCII letters, so this is effectively a passthrough, but we
        // encode defensively.
        let encodedLocale = languageCode.addingPercentEncoding(withAllowedCharacters: .guaURLQueryValueAllowed) ?? languageCode
        let param = "ui_locales=\(encodedLocale)"

        if let existing = percentEncodedQuery, !existing.isEmpty {
            percentEncodedQuery = existing + "&" + param
        } else {
            percentEncodedQuery = param
        }
    }
}

private extension CharacterSet {
    /// Characters allowed unescaped in a single query-parameter **value** (RFC 3986 `query` minus the
    /// sub-delimiters that carry meaning inside a query string, plus `+` which a form-urlencoded
    /// parser would read as a space).
    static let guaURLQueryValueAllowed: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "+&=?#")
        return set
    }()
}
