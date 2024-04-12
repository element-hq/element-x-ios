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
import MatrixRustSDK

struct AttributedStringBuilder: AttributedStringBuilderProtocol {
    private let cacheKey: String
    private let temporaryBlockquoteMarkingColor = UIColor.magenta
    private let temporaryCodeBlockMarkingColor = UIColor.cyan
    private let mentionBuilder: MentionBuilderProtocol
    
    private static let defaultKey = "default"
    
    private static let cacheDispatchQueue = DispatchQueue(label: "io.element.elementx.attributed_string_builder_cache")
    private static var caches: [String: LRUCache<String, AttributedString>] = [:]

    static func invalidateCaches() {
        caches.removeAll()
    }
    
    init(cacheKey: String = defaultKey, mentionBuilder: MentionBuilderProtocol) {
        self.cacheKey = cacheKey
        self.mentionBuilder = mentionBuilder
    }
        
    func fromPlain(_ string: String?) -> AttributedString? {
        guard let string else {
            return nil
        }
        
        if let cached = Self.cachedValue(forKey: string, cacheKey: cacheKey) {
            return cached
        }

        let mutableAttributedString = NSMutableAttributedString(string: string)
        addLinksAndMentions(mutableAttributedString)
        detectPermalinks(mutableAttributedString)
        removeLinkColors(mutableAttributedString)
        
        let result = try? AttributedString(mutableAttributedString, including: \.elementX)
        Self.cacheValue(result, forKey: string, cacheKey: cacheKey)
        
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
        guard let originalHTMLString = htmlString else {
            return nil
        }
        
        if let cached = Self.cachedValue(forKey: originalHTMLString, cacheKey: cacheKey) {
            return cached
        }
                
        let htmlString = originalHTMLString.replacingHtmlBreaksOccurrences()
        
        guard let data = htmlString.data(using: .utf8) else {
            return nil
        }
        
        let defaultFont = UIFont.preferredFont(forTextStyle: .body)
        
        let parsingOptions: [String: Any] = [
            DTUseiOS6Attributes: true,
            DTDefaultFontFamily: defaultFont.familyName,
            DTDefaultFontName: defaultFont.fontName,
            DTDefaultFontSize: defaultFont.pointSize,
            DTDefaultStyleSheet: DTCSSStylesheet(styleBlock: defaultCSS) as Any,
            DTDefaultLinkDecoration: false
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
        addLinksAndMentions(mutableAttributedString)
        replaceMarkedBlockquotes(mutableAttributedString)
        replaceMarkedCodeBlocks(mutableAttributedString)
        detectPermalinks(mutableAttributedString)
        removeLinkColors(mutableAttributedString)
        removeDTCoreTextArtifacts(mutableAttributedString)
        
        let result = try? AttributedString(mutableAttributedString, including: \.elementX)
        Self.cacheValue(result, forKey: htmlString, cacheKey: cacheKey)
        
        return result
    }
    
    // MARK: - Private
    
    private static func cacheValue(_ value: AttributedString?, forKey key: String, cacheKey: String) {
        cacheDispatchQueue.sync {
            if caches[cacheKey] == nil {
                caches[cacheKey] = LRUCache<String, AttributedString>(countLimit: 1000)
            }
            
            caches[cacheKey]?.setValue(value, forKey: key)
        }
    }
    
    private static func cachedValue(forKey key: String, cacheKey: String) -> AttributedString? {
        var result: AttributedString?
        cacheDispatchQueue.sync {
            result = caches[cacheKey]?.value(forKey: key)
        }
        
        return result
    }
    
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
    
    private func replaceMarkedCodeBlocks(_ attributedString: NSMutableAttributedString) {
        attributedString.enumerateAttribute(.backgroundColor, in: .init(location: 0, length: attributedString.length), options: []) { value, range, _ in
            if let value = value as? UIColor,
               value == temporaryCodeBlockMarkingColor {
                attributedString.addAttribute(.backgroundColor, value: UIColor(.compound._bgCodeBlock) as Any, range: range)
                // Codebloks should not have explicit links
                attributedString.enumerateAttribute(.link, in: range, options: []) { value, range, _ in
                    if let link = value as? URL {
                        var text = attributedString.attributedSubstring(from: range).string
                        if !text.contains("://") {
                            // we sanitize links by always  them use https://
                            text.insert(contentsOf: "https://", at: text.startIndex)
                        }
                        if text == link.absoluteString {
                            attributedString.removeAttribute(.link, range: range)
                        }
                    }
                }
                // Codeblocks should not have all users mentions
                attributedString.removeAttribute(.MatrixAllUsersMention, range: range)
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
    
    private func addLinksAndMentions(_ attributedString: NSMutableAttributedString) {
        let string = attributedString.string
        
        // Event identifiers and room aliases and identifiers detected in plain text are techincally incomplete
        // without via parameters and we won't bother detecting them
        
        var matches: [TextParsingMatch] = MatrixEntityRegex.userIdentifierRegex.matches(in: string, options: []).compactMap { match in
            guard let matchRange = Range(match.range, in: string) else {
                return nil
            }
            
            let identifier = String(string[matchRange])

            return TextParsingMatch(type: .userID(identifier: identifier), range: match.range)
        }
        
        matches.append(contentsOf: MatrixEntityRegex.linkRegex.matches(in: string, options: []).compactMap { match in
            guard let matchRange = Range(match.range, in: string) else {
                return nil
            }
            
            var link = String(string[matchRange])
            
            if !link.contains("://") {
                link.insert(contentsOf: "https://", at: link.startIndex)
            }
            
            return TextParsingMatch(type: .link(urlString: link), range: match.range)
        })
        
        matches.append(contentsOf: MatrixEntityRegex.allUsersRegex.matches(in: attributedString.string, options: []).map { match in
            TextParsingMatch(type: .atRoom, range: match.range)
        })
        
        guard matches.count > 0 else {
            return
        }
        
        // Sort the links by length so the longest one always takes priority
        matches.sorted { $0.range.length > $1.range.length }.forEach { [attributedString] match in
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
            
            switch match.type {
            case .atRoom:
                attributedString.addAttribute(.MatrixAllUsersMention, value: true, range: match.range)
            case .userID, .link:
                if let url = match.link {
                    attributedString.addAttribute(.link, value: url, range: match.range)
                }
            }
        }
    }
    
    func detectPermalinks(_ attributedString: NSMutableAttributedString) {
        attributedString.enumerateAttribute(.link, in: .init(location: 0, length: attributedString.length), options: []) { value, range, _ in
            if value != nil {
                if let url = value as? URL, let matrixEntity = parseMatrixEntityFrom(uri: url.absoluteString) {
                    switch matrixEntity.id {
                    case .user(let userID):
                        mentionBuilder.handleUserMention(for: attributedString, in: range, url: url, userID: userID)
                    case .room(let roomID):
                        attributedString.addAttributes([.MatrixRoomID: roomID], range: range)
                    case .roomAlias(let alias):
                        attributedString.addAttributes([.MatrixRoomAlias: alias], range: range)
                    case .eventOnRoomId(let roomID, let eventID):
                        attributedString.addAttributes([.MatrixEventOnRoomID: EventOnRoomIDAttribute.Value(roomID: roomID, eventID: eventID)], range: range)
                    case .eventOnRoomAlias(let alias, let eventID):
                        attributedString.addAttributes([.MatrixEventOnRoomAlias: EventOnRoomAliasAttribute.Value(alias: alias, eventID: eventID)], range: range)
                    }
                }
            }
        }
        
        attributedString.enumerateAttribute(.MatrixAllUsersMention, in: .init(location: 0, length: attributedString.length), options: []) { value, range, _ in
            if let value = value as? Bool,
               value {
                mentionBuilder.handleAllUsersMention(for: attributedString, in: range)
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
    static let MatrixEventOnRoomID: NSAttributedString.Key = .init(rawValue: EventOnRoomIDAttribute.name)
    static let MatrixEventOnRoomAlias: NSAttributedString.Key = .init(rawValue: EventOnRoomAliasAttribute.name)
    static let MatrixAllUsersMention: NSAttributedString.Key = .init(rawValue: AllUsersMentionAttribute.name)
}

protocol MentionBuilderProtocol {
    func handleUserMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, userID: String)
    func handleAllUsersMention(for attributedString: NSMutableAttributedString, in range: NSRange)
}

private struct TextParsingMatch {
    enum MatchType {
        case userID(identifier: String)
        case link(urlString: String)
        case atRoom
    }
    
    let type: MatchType
    let range: NSRange
    
    var link: URL? {
        switch type {
        case .userID(let identifier):
            return try? URL(string: matrixToUserPermalink(userId: identifier))
        case .link(let urlString):
            return URL(string: urlString)
        default:
            return nil
        }
    }
}
