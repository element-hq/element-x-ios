//
//  UserDisplayName.swift
//  TchapX
//
//  Created by Nicolas Buquet on 09/10/2024.
//  Copyright © 2024 Tchap. All rights reserved.
//

import Foundation

struct UserDisplayName {
    private static let DOMAIN_PREFIX: Character = "["
    private static let DOMAIN_SUFFIX: Character = "]" // Not used at the moment.

    private var _displayName: String

    /// Must be initiated from a user's disaplynName as "Jean Martin `[Modernisation]`".

    init(_ displayName: String) {
        _displayName = displayName
    }
    
    /// Return the raw displayName.
    
    var displayName: String {
        _displayName
    }
    
    /// Get name part of a display name by removing the domain part if any.
    ///
    /// - Returns:displayName without domain (or the display name itself if no domain has been found).
    ///
    /// For example in case of "Jean Martin `[Modernisation]`", this will return "Jean Martin".
    
    var userName: String {
        guard let splitIndex = displayName.firstIndex(of: Self.DOMAIN_PREFIX) else {
            return _displayName
        }
        return _displayName.prefix(upTo: splitIndex).trimmingCharacters(in: .whitespaces)
    }
    
    ///  Get the potential domain name from a display name.
    ///
    ///  - Returns: displayName without name, empty string if no domain is available.
    ///
    ///  For example in case of "Jean Martin `[Modernisation]`", this will return "Modernisation".
    
    var userDomain: String {
        guard let domain = _displayName.firstMatch(of: /^.*\[(.*?)\].*$/) else {
            return ""
        }
        return domain.output.1.trimmingCharacters(in: .whitespaces)
    }
}
