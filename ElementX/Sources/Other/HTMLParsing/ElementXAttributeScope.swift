//
//  ElementXAttributeScope.swift
//  ElementX
//
//  Created by Stefan Ceriu on 23/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

enum BlockquoteAttribute: AttributedStringKey {
    typealias Value = Bool
    public static var name = "MXBlockquoteAttribute"
}

extension AttributeScopes {
    struct ElementXAttributes: AttributeScope {
        let blockquote: BlockquoteAttribute
        
        let swiftUI: SwiftUIAttributes
        let uiKit: UIKitAttributes
    }
    
    var elementX: ElementXAttributes.Type { ElementXAttributes.self }
}

extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.ElementXAttributes, T>) -> T {
        self[T.self]
    }
}
