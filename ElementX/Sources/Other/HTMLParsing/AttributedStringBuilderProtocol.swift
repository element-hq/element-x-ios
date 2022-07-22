//
//  AttributedStringBuilderProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 24/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

struct AttributedStringBuilderComponent: Hashable {
    let attributedString: AttributedString
    let isBlockquote: Bool
}

protocol AttributedStringBuilderProtocol {
    func fromPlain(_ string: String?) -> AttributedString?
    func fromPlain(_ string: String?) async -> AttributedString?
    
    func fromHTML(_ htmlString: String?) -> AttributedString?
    func fromHTML(_ htmlString: String?) async -> AttributedString?
    
    func blockquoteCoalescedComponentsFrom(_ attributedString: AttributedString?) -> [AttributedStringBuilderComponent]?
}
