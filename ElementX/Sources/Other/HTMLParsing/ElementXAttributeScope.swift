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
