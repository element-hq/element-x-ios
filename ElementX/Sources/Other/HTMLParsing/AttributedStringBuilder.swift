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
    private let cacheKey: String
    private let temporaryBlockquoteMarkingColor = UIColor.magenta
    private let temporaryCodeBlockMarkingColor = UIColor.cyan
    private let linkColor = UIColor.blue
    private let permalinkBaseURL: URL
    private let mentionBuilder: MentionBuilderProtocol
    
    private static let defaultKey = "default"
    private static var caches: [String: LRUCache<String, AttributedString>] = [:]

    static func invalidateCaches() {
        caches.removeAll()
    }
    
    static func invalidateCache(for key: String = defaultKey) {
        caches[key]?.removeAllValues()
    }
    
    init(cacheKey: String = defaultKey, permalinkBaseURL: URL, mentionBuilder: MentionBuilderProtocol) {
        self.cacheKey = cacheKey
        if Self.caches[cacheKey] == nil {
            Self.caches[cacheKey] = LRUCache<String, AttributedString>(countLimit: 1000)
        }
        self.permalinkBaseURL = permalinkBaseURL
        self.mentionBuilder = mentionBuilder
    }
        
    func fromPlain(_ string: String?) -> AttributedString? {
        guard let string else {
            return nil
        }
        
        if let cached = Self.caches[cacheKey]?.value(forKey: string) {
            return cached
        }

        let mutableAttributedString = NSMutableAttributedString(string: string)
        addLinksAndMentions(mutableAttributedString)
        detectPermalinks(mutableAttributedString)
        removeLinkColors(mutableAttributedString)
        
        let result = try? AttributedString(mutableAttributedString, including: \.elementX)
        Self.caches[cacheKey]?.setValue(result, forKey: string)
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
        guard var originalHTMLString = htmlString else {
            return nil
        }
        
        if let cached = Self.caches[cacheKey]?.value(forKey: originalHTMLString) {
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
        Self.caches[cacheKey]?.setValue(result, forKey: htmlString)
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
    
    private func replaceMarkedCodeBlocks(_ attributedString: NSMutableAttributedString) {
        attributedString.enumerateAttribute(.backgroundColor, in: .init(location: 0, length: attributedString.length), options: []) { value, range, _ in
            if let value = value as? UIColor,
               value == temporaryCodeBlockMarkingColor {
                attributedString.addAttribute(.backgroundColor, value: UIColor(.compound._bgCodeBlock) as Any, range: range)
                // Codeblocks should not have links and all users mentions
                attributedString.removeAttribute(.link, range: range)
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
        
        var matches = MatrixEntityRegex.userIdentifierRegex.matches(in: string, options: []).map { TypedMatch(match: $0, type: .permalink(type: .userID)) }
        matches.append(contentsOf: MatrixEntityRegex.roomIdentifierRegex.matches(in: string, options: []).map { TypedMatch(match: $0, type: .permalink(type: .roomID)) })
        
        // As of right now we do not handle event id links in any way so there is no need to add them as links
        // matches.append(contentsOf: MatrixEntityRegex.eventIdentifierRegex.matches(in: string, options: []))
        
        matches.append(contentsOf: MatrixEntityRegex.roomAliasRegex.matches(in: string, options: []).map { TypedMatch(match: $0, type: .permalink(type: .roomAlias)) })
        
        matches.append(contentsOf: MatrixEntityRegex.linkRegex.matches(in: string, options: []).map { TypedMatch(match: $0, type: .link) })
        
        matches.append(contentsOf: MatrixEntityRegex.allUsersRegex.matches(in: attributedString.string, options: []).map { TypedMatch(match: $0, type: .atRoom) })
        
        guard matches.count > 0 else {
            return
        }
        // Sort the links by length so the longest one always takes priority
        matches.sorted { $0.match.range.length > $1.match.range.length }.forEach { [attributedString] typedMatch in
            guard let matchRange = Range(typedMatch.match.range, in: string) else {
                return
            }
            
            var hasLink = false
            attributedString.enumerateAttribute(.link, in: typedMatch.match.range, options: []) { value, _, stop in
                if value != nil {
                    hasLink = true
                    stop.pointee = true
                }
            }
            
            if hasLink {
                return
            }
            
            switch typedMatch.type {
            case .atRoom:
                attributedString.addAttribute(.MatrixAllUsersMention, value: true, range: typedMatch.match.range)
            case let .permalink(type):
                let identifier = String(string[matchRange])
                
                if let url = type.getPermalinkFrom(identifier: identifier, baseURL: permalinkBaseURL) {
                    attributedString.addAttribute(.link, value: url, range: typedMatch.match.range)
                }
            case .link:
                var link = String(string[matchRange])
                
                if !link.contains("://") {
                    link.insert(contentsOf: "https://", at: link.startIndex)
                }
                
                if let url = URL(string: link) {
                    attributedString.addAttribute(.link, value: url, range: typedMatch.match.range)
                }
            }
        }
    }
    
    func detectPermalinks(_ attributedString: NSMutableAttributedString) {
        attributedString.enumerateAttribute(.link, in: .init(location: 0, length: attributedString.length), options: []) { value, range, _ in
            if value != nil {
                if let url = value as? URL {
                    switch PermalinkBuilder.detectPermalink(in: url, baseURL: permalinkBaseURL) {
                    case .userIdentifier(let identifier):
                        mentionBuilder.handleUserMention(for: attributedString, in: range, url: url, userID: identifier)
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
    static let MatrixEventID: NSAttributedString.Key = .init(rawValue: EventIDAttribute.name)
    static let MatrixAllUsersMention: NSAttributedString.Key = .init(rawValue: AllUsersMentionAttribute.name)
}

protocol MentionBuilderProtocol {
    func handleUserMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, userID: String)
    func handleAllUsersMention(for attributedString: NSMutableAttributedString, in range: NSRange)
}

private struct TypedMatch {
    enum MatchType {
        case permalink(type: MentionType)
        case link
        case atRoom
    }
    
    enum MentionType {
        case roomAlias
        case roomID
        case userID
        
        func getPermalinkFrom(identifier: String, baseURL: URL) -> URL? {
            switch self {
            case .roomAlias:
                return try? PermalinkBuilder.permalinkTo(roomAlias: identifier, baseURL: baseURL)
            case .roomID:
                return try? PermalinkBuilder.permalinkTo(roomIdentifier: identifier, baseURL: baseURL)
            case .userID:
                return try? PermalinkBuilder.permalinkTo(userIdentifier: identifier, baseURL: baseURL)
            }
        }
    }
    
    let match: NSTextCheckingResult
    let type: MatchType
}
