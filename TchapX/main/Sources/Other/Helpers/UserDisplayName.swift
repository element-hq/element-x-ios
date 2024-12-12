/*
 * MIT License
 *
 * Copyright (c) 2024. DINUM
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
 * OR OTHER DEALINGS IN THE SOFTWARE.
 */

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
