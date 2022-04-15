//
//  DTHTMLElement+AttributedStringBuilder.swift
//  ElementX
//
//  Created by Stefan Ceriu on 24/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import DTCoreText

public extension DTHTMLElement {
    /// Sanitize the element using the given parameters.
    /// - Parameters:
    ///   - font: The default font to use when resetting the content of any unsupported tags.
    @objc func sanitize(font: UIFont) {
        if let name = name, !Self.allowedHTMLTags.contains(name) {
            
            // This is an unsupported tag.
            // Remove any attachments to fix rendering.
            textAttachment = nil
            
            // If the element has plain text content show that,
            // otherwise prevent the tag from displaying.
            if let stringContent = attributedString()?.string,
               !stringContent.isEmpty,
               let element = DTTextHTMLElement(name: nil, attributes: nil) {
                element.setText(stringContent)
                removeAllChildNodes()
                addChildNode(element)
                
                if let parent = parent() {
                    element.inheritAttributes(from: parent)
                } else {
                    fontDescriptor = DTCoreTextFontDescriptor()
                    fontDescriptor.fontFamily = font.familyName
                    fontDescriptor.fontName = font.fontName
                    fontDescriptor.pointSize = font.pointSize
                    paragraphStyle = DTCoreTextParagraphStyle.default()
                    
                    element.inheritAttributes(from: self)
                }
                element.interpretAttributes()
                
            } else if let parent = parent() {
                parent.removeChildNode(self)
            } else {
                didOutput = true
            }
            
        } else {
            // This element is a supported tag, but it may contain children that aren't,
            // so santize all child nodes to ensure correct tags.
            if let childNodes = childNodes as? [DTHTMLElement] {
                childNodes.forEach { $0.sanitize(font: font) }
            }
        }
    }
    
    private static var allowedHTMLTags = {
        ["font", // custom to matrix for IRC-style font coloring
         "del", // for markdown
         "body", // added internally by DTCoreText
         "mx-reply",
         "h1", "h2", "h3", "h4", "h5", "h6", "blockquote", "p", "a", "ul", "ol",
         "nl", "li", "b", "i", "u", "strong", "em", "strike", "code", "hr", "br", "div",
         "table", "thead", "caption", "tbody", "tr", "th", "td", "pre"]
    }()
}
