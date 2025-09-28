//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

protocol AllValues {
    associatedtype ValueType
    var allValues: [(name: String, value: ValueType)] { get }
}

extension AllValues {
    var allValues: [(name: String, value: ValueType)] {
        var values: [(name: String, value: ValueType)] = []
        let mirror = Mirror(reflecting: self)
        
        for property in mirror.children {
            if let label = property.label, let value = property.value as? ValueType {
                values.append((label, value))
            }
        }
        
        return values
    }
}

extension CompoundColors: AllValues { typealias ValueType = Color }
extension CompoundColorTokens: AllValues { typealias ValueType = Color }
extension CompoundGradients: AllValues { typealias ValueType = Gradient }
extension CompoundFonts: AllValues { typealias ValueType = Font }
extension CompoundIcons: AllValues { typealias ValueType = Image }

extension CompoundColors {
    var allColors: [(name: String, value: Color)] {
        CompoundColorTokens().allValues + allValues
    }
}

extension CompoundIcons {
    var allKeyPaths: [(name: String, value: KeyPath<CompoundIcons, Image>)] {
        var icons: [(name: String, value: KeyPath<CompoundIcons, Image>)] = []
        let mirror = Mirror(reflecting: self)
        
        for property in mirror.children {
            if let label = property.label {
                let keyPath = \CompoundIcons.[checkedMirrorDescendant: label] as PartialKeyPath
                
                if let imageKeyPath = keyPath as? KeyPath<CompoundIcons, Image> {
                    icons.append((label, imageKeyPath))
                } else {
                    print("Nope")
                }
            }
        }
        
        return icons
    }
    
    private subscript(checkedMirrorDescendant key: String) -> Any {
        return Mirror(reflecting: self).descendant(key)!
    }
}
