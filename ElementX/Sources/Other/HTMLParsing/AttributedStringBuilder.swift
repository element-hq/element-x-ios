//
//  AttributedStringBuilder.swift
//  ElementX
//
//  Created by Stefan Ceriu on 22/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import DTCoreText

struct AttributedStringBuilder: AttributedStringBuilderProtocol {
    
    private let temporaryBlockquoteMarkingColor = UIColor.magenta
    private let temporaryCodeBlockMarkingColor = UIColor.cyan
    private let linkColor = UIColor.blue
    
    private let userIdDetector: NSRegularExpression
    private let roomIdDetector: NSRegularExpression
    private let eventIdDetector: NSRegularExpression
    private let roomAliasDetector: NSRegularExpression
    private let linkDetector: NSDataDetector
    
    init() {
        do {
            userIdDetector = try NSRegularExpression(pattern: MatrixEntityRegex.userId.rawValue, options: .caseInsensitive)
            roomIdDetector = try NSRegularExpression(pattern: MatrixEntityRegex.roomId.rawValue, options: .caseInsensitive)
            eventIdDetector = try NSRegularExpression(pattern: MatrixEntityRegex.eventId.rawValue, options: .caseInsensitive)
            roomAliasDetector = try NSRegularExpression(pattern: MatrixEntityRegex.roomAlias.rawValue, options: .caseInsensitive)
            linkDetector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        } catch {
            fatalError()
        }
    }
    
    func fromPlain(_ string: String?) -> AttributedString? {
        guard let string = string else {
            return nil
        }

        let mutableAttributedString = NSMutableAttributedString(string: string)
        addLinks(mutableAttributedString)
        removeLinkColors(mutableAttributedString)
        
        return try? AttributedString(mutableAttributedString, including: \.elementX)
    }
    
    // Do not use the default HTML renderer of NSAttributedString because this method
    // runs on the UI thread which we want to avoid because renderHTMLString is called
    // most of the time from a background thread.
    // Use DTCoreText HTML renderer instead.
    // Using DTCoreText, which renders static string, helps to avoid code injection attacks
    // that could happen with the default HTML renderer of NSAttributedString which is a
    // webview.
    func fromHTML(_ htmlString: String?) -> AttributedString? {
        guard let htmlString = htmlString,
              let data = htmlString.data(using: .utf8) else {
                  return nil
              }
        
        let defaultFont = UIFont.preferredFont(forTextStyle: .body)
        
        let parsingOptions: [String: Any] = [
            DTUseiOS6Attributes: true,
            DTDefaultFontFamily: defaultFont.familyName,
            DTDefaultFontName: defaultFont.fontName,
            DTDefaultFontSize: defaultFont.pointSize,
            DTDefaultStyleSheet: DTCSSStylesheet(styleBlock: self.defaultCSS) as Any
        ]
        
        guard let builder = DTHTMLAttributedStringBuilder(html: data, options: parsingOptions, documentAttributes: nil) else {
            return nil
        }
        
        builder.willFlushCallback = { element in
            element?.sanitize(font: defaultFont)
        }
            
        guard let attributedString = builder.generatedAttributedString() else {
            return nil
        }
        
        let mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
        removeDefaultForegroundColor(mutableAttributedString)
        addLinks(mutableAttributedString)
        removeLinkColors(mutableAttributedString)
        replaceMarkedBlockquotes(mutableAttributedString)
        replaceMarkedCodeBlocks(mutableAttributedString)
        removeDTCoreTextArtifacts(mutableAttributedString)
        
        return try? AttributedString(mutableAttributedString, including: \.elementX)
    }
    
    func blockquoteCoalescedComponentsFrom(_ attributedString: AttributedString?) -> [AttributedStringBuilderComponent]? {
        guard let attributedString = attributedString else {
            return nil
        }
        
        return attributedString.runs[\.blockquote].map { (value, range) in
            var attributedString = AttributedString(attributedString[range])
            
            // Remove trailing new lines if any
            if let lastCharacter = attributedString.characters.last,
               lastCharacter.isNewline {
                attributedString = AttributedString(attributedString.characters.dropLast())
            }
            
            return AttributedStringBuilderComponent(attributedString: attributedString, isBlockquote: value != nil)
        }
    }
    
    // MARK: - Private
    
    private func replaceMarkedBlockquotes(_ attributedString: NSMutableAttributedString) {
        // According to blockquotes in the string, DTCoreText can apply 2 policies:
        //     - define a `DTTextBlocksAttribute` attribute on a <blockquote> block
        //     - or, just define a `NSBackgroundColorAttributeName` attribute
        attributedString.enumerateAttribute(.DTTextBlocks, in: .init(location: 0, length: attributedString.length), options: []) { value, range, _ in
            guard let value = value as? NSArray,
                  let dtTextBlock = value.firstObject as? DTTextBlock,
                  dtTextBlock.backgroundColor == temporaryBlockquoteMarkingColor else {
                      return
                  }
            
            attributedString.addAttribute(.MXBlockquote, value: true, range: range)
        }
        
        attributedString.enumerateAttribute(.backgroundColor, in: .init(location: 0, length: attributedString.length), options: []) { value, range, _ in
            guard let value = value as? UIColor,
                  value == temporaryBlockquoteMarkingColor else {
                      return
                  }
            
            attributedString.removeAttribute(.backgroundColor, range: range)
            attributedString.addAttribute(.MXBlockquote, value: true, range: range)
        }
    }
    
    func replaceMarkedCodeBlocks(_ attributedString: NSMutableAttributedString) {
        attributedString.enumerateAttribute(.backgroundColor, in: .init(location: 0, length: attributedString.length), options: []) { value, range, _ in
            if let value = value as? UIColor,
               value == temporaryCodeBlockMarkingColor {
                attributedString.addAttribute(.backgroundColor, value: UIColor.codeBlockBackgroundColor as Any, range: range)
            }
        }
    }
    
    private func removeDTCoreTextArtifacts(_ attributedString: NSMutableAttributedString) {
        guard attributedString.length > 0 else {
            return
        }
        
        // DTCoreText adds a newline at the end of plain text ( https://github.com/Cocoanetics/DTCoreText/issues/779 )
        // or after a blockquote section.
        // Trim trailing whitespace and newlines in the string content
        while (attributedString.string as NSString).hasSuffixCharacter(from: .whitespacesAndNewlines) {
            attributedString.deleteCharacters(in: .init(location: attributedString.length - 1, length: 1))
        }
    }
    
    private func addLinks(_ attributedString: NSMutableAttributedString) {
        
        let string = attributedString.string
        let range = NSRange(location: 0, length: attributedString.string.count)
        
        var matches = userIdDetector.matches(in: string, options: [], range: range)
        matches.append(contentsOf: roomIdDetector.matches(in: string, options: [], range: range))
        matches.append(contentsOf: eventIdDetector.matches(in: string, options: [], range: range))
        matches.append(contentsOf: roomAliasDetector.matches(in: string, options: [], range: range))
        matches.append(contentsOf: linkDetector.matches(in: string, options: [], range: range))
        
        guard matches.count > 0 else {
            return
        }
        
        matches.forEach { match in
            guard let matchRange = Range(match.range, in: string) else {
                return
            }
            
            var hasLink = false
            attributedString.enumerateAttribute(.link, in: match.range, options: []) { value, _, stop in
                if value != nil {
                    hasLink = true
                    stop.pointee = true
                }
            }
            
            if hasLink {
                return
            }
            
            let link = string[matchRange].addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            attributedString.addAttribute(.link, value: link as Any, range: match.range)
        }
    }
    
    private func removeDefaultForegroundColor(_ attributedString: NSMutableAttributedString) {
        attributedString.enumerateAttribute(.foregroundColor, in: .init(location: 0, length: attributedString.length), options: []) { value, range, _ in
            if value as? UIColor == UIColor.black {
                attributedString.removeAttribute(.foregroundColor, range: range)
            }
        }
    }
    
    private func removeLinkColors(_ attributedString: NSMutableAttributedString) {
        attributedString.enumerateAttribute(.link, in: .init(location: 0, length: attributedString.length), options: []) { value, range, _ in
            if value != nil {
                attributedString.removeAttribute(.foregroundColor, range: range)
            }
        }
    }
    
    private var defaultCSS: String {
"""
        blockquote {
            background: \(temporaryBlockquoteMarkingColor.toHexString());
            display: block;
        }
        pre,code {
            background-color: \(temporaryCodeBlockMarkingColor.toHexString());
            display: inline;
            font-family: monospace;
            white-space: pre;
            -coretext-fontname: Menlo-Regular;
        }
        h1,h2,h3 {
            font-size: 1.2em;
        }
"""
    }
}

extension UIColor {
    func toHexString() -> String {
        var red: CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat = 0.0
        var alpha: CGFloat = 0.0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red*255)<<16 | (Int)(green*255)<<8 | (Int)(blue*255)<<0
        
        return NSString(format: "#%06x", rgb) as String
    }
}

extension NSAttributedString.Key {
    static let DTTextBlocks: NSAttributedString.Key = .init(rawValue: DTTextBlocksAttribute)
    static let MXBlockquote: NSAttributedString.Key = .init(rawValue: BlockquoteAttribute.name)
}
