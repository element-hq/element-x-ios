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

import DTCoreText
import Foundation
import LRUCache

struct AttributedStringBuilder: AttributedStringBuilderProtocol {
    private let temporaryBlockquoteMarkingColor = UIColor.magenta
    private let temporaryCodeBlockMarkingColor = UIColor.cyan
    private let linkColor = UIColor.blue
    private let permalinkBaseURL: URL
    
    private static var cache = LRUCache<String, AttributedString>(countLimit: 1000)

    static func invalidateCache() {
        cache.removeAllValues()
    }
    
    init(permalinkBaseURL: URL) {
        self.permalinkBaseURL = permalinkBaseURL
    }
        
    func fromPlain(_ string: String?) -> AttributedString? {
        guard let string else {
            return nil
        }
        
        if let cached = Self.cache.value(forKey: string) {
            return cached
        }

        let mutableAttributedString = NSMutableAttributedString(string: string)
        addLinks(mutableAttributedString)
        removeLinkColors(mutableAttributedString)
        
        let result = try? AttributedString(mutableAttributedString, including: \.elementX)
        Self.cache.setValue(result, forKey: string)
        return result
    }
        
    // Do not use the default HTML renderer of NSAttributedString because this method
    // runs on the UI thread which we want to avoid because renderHTMLString is called
    // most of the time from a background thread.
    // Use DTCoreText HTML renderer instead.
    // Using DTCoreText, which renders static string, helps to avoid code injection attacks
    // that could happen with the default HTML renderer of NSAttributedString which is a
    // webview.
    func fromHTML(_ htmlString: String?) -> AttributedString? {
        guard let htmlString else {
            return nil
        }
        
        if let cached = Self.cache.value(forKey: htmlString) {
            return cached
        }
        
        guard let data = htmlString.data(using: .utf8) else {
            return nil
        }
        
        let defaultFont = UIFont.preferredFont(forTextStyle: .body)
        
        let parsingOptions: [String: Any] = [
            DTUseiOS6Attributes: true,
            DTDefaultFontFamily: defaultFont.familyName,
            DTDefaultFontName: defaultFont.fontName,
            DTDefaultFontSize: defaultFont.pointSize,
            DTDefaultStyleSheet: DTCSSStylesheet(styleBlock: defaultCSS) as Any
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
        detectPermalinks(mutableAttributedString)
        removeLinkColors(mutableAttributedString)
        replaceMarkedBlockquotes(mutableAttributedString)
        replaceMarkedCodeBlocks(mutableAttributedString)
        removeDTCoreTextArtifacts(mutableAttributedString)
        
        let result = try? AttributedString(mutableAttributedString, including: \.elementX)
        Self.cache.setValue(result, forKey: htmlString)
        return result
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
            
            attributedString.addAttribute(.MatrixBlockquote, value: true, range: range)
        }
        
        attributedString.enumerateAttribute(.backgroundColor, in: .init(location: 0, length: attributedString.length), options: []) { value, range, _ in
            guard let value = value as? UIColor,
                  value == temporaryBlockquoteMarkingColor else {
                return
            }
            
            attributedString.removeAttribute(.backgroundColor, range: range)
            attributedString.addAttribute(.MatrixBlockquote, value: true, range: range)
        }
    }
    
    func replaceMarkedCodeBlocks(_ attributedString: NSMutableAttributedString) {
        attributedString.enumerateAttribute(.backgroundColor, in: .init(location: 0, length: attributedString.length), options: []) { value, range, _ in
            if let value = value as? UIColor,
               value == temporaryCodeBlockMarkingColor {
                attributedString.addAttribute(.backgroundColor, value: UIColor(.compound._bgCodeBlock) as Any, range: range)
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
        
        var matches = MatrixEntityRegex.userIdentifierRegex.matches(in: string, options: [])
        matches.append(contentsOf: MatrixEntityRegex.roomIdentifierRegex.matches(in: string, options: []))
        // As of right now we do not handle event id links in any way so there is no need to add them as links
        // matches.append(contentsOf: MatrixEntityRegex.eventIdentifierRegex.matches(in: string, options: []))
        matches.append(contentsOf: MatrixEntityRegex.roomAliasRegex.matches(in: string, options: []))
        
        let linkMatches = MatrixEntityRegex.linkRegex.matches(in: string, options: [])
        matches.append(contentsOf: linkMatches)
        guard matches.count > 0 else {
            return
        }
        
        // Sort the links by length so the longest one always takes priority
        matches.sorted { $0.range.length > $1.range.length }.forEach { match in
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
            
            var link = String(string[matchRange])
            
            if linkMatches.contains(match), !link.contains("://") {
                link.insert(contentsOf: "https://", at: link.startIndex)
            }
            
            attributedString.addAttribute(.link, value: link as Any, range: match.range)
        }
    }
    
    private func detectPermalinks(_ attributedString: NSMutableAttributedString) {
        attributedString.enumerateAttribute(.link, in: .init(location: 0, length: attributedString.length), options: []) { value, range, _ in
            if value != nil {
                if let url = value as? URL {
                    switch PermalinkBuilder.detectPermalink(in: url, baseURL: permalinkBaseURL) {
                    case .userIdentifier(let identifier):
                        attributedString.addAttributes([.MatrixUserID: identifier], range: range)
                    case .roomIdentifier(let identifier):
                        attributedString.addAttributes([.MatrixRoomID: identifier], range: range)
                    case .roomAlias(let alias):
                        attributedString.addAttributes([.MatrixRoomAlias: alias], range: range)
                    case .event(let roomIdentifier, let eventIdentifier):
                        attributedString.addAttributes([.MatrixEventID: EventIDAttributeValue(roomID: roomIdentifier, eventID: eventIdentifier)], range: range)
                    case .none:
                        break
                    }
                }
            }
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
                    white-space: pre;
                    font-size: 0.9em;
                    -coretext-fontname: .AppleSystemUIFontMonospaced-Regular;
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
        
        let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255) << 0
        
        return NSString(format: "#%06x", rgb) as String
    }
}

extension NSAttributedString.Key {
    static let DTTextBlocks: NSAttributedString.Key = .init(rawValue: DTTextBlocksAttribute)
    static let MatrixBlockquote: NSAttributedString.Key = .init(rawValue: BlockquoteAttribute.name)
    static let MatrixUserID: NSAttributedString.Key = .init(rawValue: UserIDAttribute.name)
    static let MatrixRoomID: NSAttributedString.Key = .init(rawValue: RoomIDAttribute.name)
    static let MatrixRoomAlias: NSAttributedString.Key = .init(rawValue: RoomAliasAttribute.name)
    static let MatrixEventID: NSAttributedString.Key = .init(rawValue: EventIDAttribute.name)
}
