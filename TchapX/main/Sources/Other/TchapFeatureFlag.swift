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
// TchapFeatureFlag.swift
// TchapX
//
// Created by Nicolas Buquet on 09/12/2024.
// Copyright © 2024 Tchap. All rights reserved.
//

import Foundation

struct TchapFeatureFlag {
    let allowedInstances: [Instance]
    
    func isActivated(for homeServer: String) -> Bool {
        // Return false if no instance suppports the feature.
        if allowedInstances.isEmpty {
            return false
        }

        // Return true if all instances support the feature.
        // Can be used for feature that takes place before login (like ProConnect login option).
        if allowedInstances.contains(.all) {
            return true
        }
        
        // Example of homeServer for authenticiation: `matrix.agent.dinum.tchap.gouv.fr`
        // We must remove the `matrix.` prefix.
        let homeServerPrefixes = ["matrix.", "https://matrix."]
        var sanitizedHomeServer = Substring(homeServer)
        homeServerPrefixes.forEach {
            if sanitizedHomeServer.hasPrefix($0) {
                sanitizedHomeServer = sanitizedHomeServer.dropFirst($0.count)
            }
        }
        
        // Verifiy that the instance is known.
        // Return false if the instance is not a known instance.
        guard let instance = Instance(rawValue: String(sanitizedHomeServer)) else {
            return false
        }
        
        // Return true if current session homeServer is listed in the instances supporting the feature.
        return allowedInstances.contains(instance)
    }
}

extension TchapFeatureFlag {
    enum Instance: String {
        case externe = "agent.externe.tchap.gouv.fr"
        case collectivites = "agent.collectivites.tchap.gouv.fr"
        case agent = "agent.tchap.gouv.fr"
        case elysee = "agent.elysee.tchap.gouv.fr"
        case pm = "agent.pm.tchap.gouv.fr"
        case ssi = "agent.ssi.tchap.gouv.fr"
        case finances = "agent.finances.tchap.gouv.fr"
        case social = "agent.social.tchap.gouv.fr"
        case interieur = "agent.interieur.tchap.gouv.fr"
        case agriculture = "agent.agriculture.tchap.gouv.fr"
        case justice = "agent.justice.tchap.gouv.fr"
        case diplomatie = "agent.diplomatie.tchap.gouv.fr"
        case intradef = "agent.intradef.tchap.gouv.fr"
        case dinum = "agent.dinum.tchap.gouv.fr"
        case culture = "agent.culture.tchap.gouv.fr"
        case devDurable = "agent.dev-durable.tchap.gouv.fr"
        case education = "agent.education.tchap.gouv.fr"
        case all // To allow a feature for any instance

        var homeServer: String? { rawValue }
    }
}

extension TchapFeatureFlag {
    enum Configuration { // Use empty Enum rather than empty Struct. (Linter advice)
        #if IS_TCHAP_PRODUCTION
        static let certificatePinning = TchapFeatureFlag(allowedInstances: [.agriculture, .agent])
        static let proConnectAuthentication = TchapFeatureFlag(allowedInstances: [])
        #elseif IS_TCHAP_STAGING
        static let certificatePinning = TchapFeatureFlag(allowedInstances: [.agriculture, .agent])
        static let proConnectAuthentication = TchapFeatureFlag(allowedInstances: [])
        #elseif IS_TCHAP_DEVELOPMENT
        static let certificatePinning = TchapFeatureFlag(allowedInstances: [.agriculture, .agent])
        static let proConnectAuthentication = TchapFeatureFlag(allowedInstances: [])
        #endif
    }
}
