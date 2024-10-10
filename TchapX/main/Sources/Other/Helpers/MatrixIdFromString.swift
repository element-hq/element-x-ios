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
//  MatrixIdFromString.swift
//  Tchap X
//
//  Created by Nicolas Buquet on 03/10/2024.
//  Copyright © 2024 Tchap. All rights reserved.
//

import Foundation

struct MatrixIdFromString {
    private var mxIdString: String
    
    init(_ mxIdString: String) {
        self.mxIdString = mxIdString
    }
    
    /// Get the homeserver name of a matrix identifier.
    ///
    /// - Returns: the homeserver name, if any, `nil` otherwise.
    ///
    /// The identifier type may be any matrix identifier type: user id, room id, ...
    ///
    /// For example in case of "@jean-philippe.martin-modernisation.fr:matrix.test.org", this will return "matrix.test.org".
    ///
    /// In case of "!AAAAAAA:matrix.test.org", this will return "matrix.test.org".
    /// 
    var homeServerName: Substring {
        guard let splitIndex = mxIdString.firstIndex(of: ":") else {
            return ""
        }
        return mxIdString[mxIdString.index(after: splitIndex)...]
    }

    /// Get the Tchap display name of the homeserver mentioned in a matrix identifier.
    ///
    /// - Returns: the Tchap display name of the homeserver.
    ///
    /// The identifier type may be any matrix identifier type: user id, room id, ...
    ///
    /// The returned name is capitalized.
    ///
    /// The Tchap HS display name is the component mentioned before the suffix "tchap.gouv.fr"
    ///
    /// For example in case of "@jean-philippe.martin-modernisation.fr:name1.tchap.gouv.fr", this will return "Name1".
    /// in case of "@jean-philippe.martin-modernisation.fr:agent.name2.tchap.gouv.fr", this will return "Name2".

    var homeServerDisplayName: Substring {
        var homeserverName = homeServerName
        if homeserverName.hasSuffix("tchap.gouv.fr") {
            let homeserverNameComponents = homeserverName.split(separator: ".")
            if homeserverNameComponents.count >= 4 {
                homeserverName = homeserverNameComponents[homeserverNameComponents.count - 4]
            }
        }
        return homeserverName.prefix(1).localizedCapitalized + homeserverName.localizedLowercase.dropFirst()
    }

    /// Tells whether a homeserver name corresponds to an external server or not.
    ///
    /// - Returns: true if external.
    
    var isExternalTchapServer: Bool {
        mxIdString.isEmpty || mxIdString.hasPrefix("e.") || mxIdString.hasPrefix("agent.externe.")
    }
    
}
