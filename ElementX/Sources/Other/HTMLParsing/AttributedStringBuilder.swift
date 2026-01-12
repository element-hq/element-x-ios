//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import LRUCache
import MatrixRustSDK
import SwiftSoup
import UIKit

protocol MentionBuilderProtocol {
    func handleUserMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, userID: String, userDisplayName: String?)
    func handleRoomIDMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, roomID: String)
    func handleRoomAliasMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, roomAlias: String, roomDisplayName: String?)
    func handleEventOnRoomAliasMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, eventID: String, roomAlias: String)
    func handleEventOnRoomIDMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, eventID: String, roomID: String)
    func handleAllUsersMention(for attributedString: NSMutableAttributedString, in range: NSRange)
}

extension NSAttributedString.Key {
    static let MatrixBlockquote: NSAttributedString.Key = .init(rawValue: BlockquoteAttribute.name)
    static let MatrixUserID: NSAttributedString.Key = .init(rawValue: UserIDAttribute.name)
    static let MatrixUserDisplayName: NSAttributedString.Key = .init(rawValue: UserDisplayNameAttribute.name)
    static let MatrixRoomDisplayName: NSAttributedString.Key = .init(rawValue: RoomDisplayNameAttribute.name)
    static let MatrixRoomID: NSAttributedString.Key = .init(rawValue: RoomIDAttribute.name)
    static let MatrixRoomAlias: NSAttributedString.Key = .init(rawValue: RoomAliasAttribute.name)
    static let MatrixEventOnRoomID: NSAttributedString.Key = .init(rawValue: EventOnRoomIDAttribute.name)
    static let MatrixEventOnRoomAlias: NSAttributedString.Key = .init(rawValue: EventOnRoomAliasAttribute.name)
    static let MatrixAllUsersMention: NSAttributedString.Key = .init(rawValue: AllUsersMentionAttribute.name)
    static let CodeBlock: NSAttributedString.Key = .init(rawValue: CodeBlockAttribute.name)
}

struct AttributedStringBuilder: AttributedStringBuilderProtocol {
    private static let defaultKey = "default"
    
    private let cacheKey: String
    private let mentionBuilder: MentionBuilderProtocol
    
    private static let attributeMSC4286 = "msc4286-external-payment-details"
    private static let cacheDispatchQueue = DispatchQueue(label: "io.element.elementx.attributed_string_builder_v2_cache")
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
        addMatrixEntityPermalinkAttributesTo(mutableAttributedString)
        
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
        
        let doc = try? SwiftSoup.parseBodyFragment(htmlString)
        
        guard let body = doc?.body() else {
            return nil
        }
        
        var listIndex = 1
        let mutableAttributedString = attributedString(element: body, documentBody: body, preserveFormatting: false, listTag: nil, listIndex: &listIndex, indentLevel: 0)
        detectPhishingAttempts(mutableAttributedString)
        addLinksAndMentions(mutableAttributedString)
        addMatrixEntityPermalinkAttributesTo(mutableAttributedString)
        removeParsingArtefacts(mutableAttributedString)
        
        let result = try? AttributedString(mutableAttributedString, including: \.elementX)
        Self.cacheValue(result, forKey: originalHTMLString, cacheKey: cacheKey)
        
        return result
    }
        
    // MARK: - Private
    
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func attributedString(element: Element,
                          documentBody: Element,
                          preserveFormatting: Bool,
                          listTag: String?,
                          listIndex: inout Int,
                          indentLevel: Int) -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        
        for node in element.getChildNodes() {
            if let textNode = node as? TextNode {
                // If this node is plain text just append its preformatted contents
                if node.parent() == documentBody {
                    result.append(NSAttributedString(string: textNode.getWholeText()))
                    continue
                }
                
                var text = preserveFormatting ? textNode.getWholeText() : textNode.text()
                
                // There seem to be sibling TextNodes following every </br> tag that
                // contain one single space character which we don't want as it
                // breaks line head indents.
                if (node.previousSibling() as? Element)?.tagName() == "br" {
                    text.trimPrefix(" ")
                }
                 
                result.append(NSAttributedString(string: text))
                continue
            }
            
            guard let childElement = node as? Element else {
                continue
            }
            
            let tag = childElement.tagName().lowercased()
            var content = NSMutableAttributedString()
            var childIndex = 1
            
            let fontPointSize = UIFont.preferredFont(forTextStyle: .body).pointSize
            
            switch tag {
            case "h1", "h2", "h3", "h4", "h5", "h6":
                let level = max(3, Int(String(tag.dropFirst())) ?? 1)
                let size: CGFloat = fontPointSize + CGFloat(6 - level) * 2
                content = attributedString(element: childElement, documentBody: documentBody, preserveFormatting: preserveFormatting, listTag: listTag, listIndex: &childIndex, indentLevel: indentLevel)
                content.append(NSAttributedString(string: "\n"))
                content.setFontPreservingSymbolicTraits(UIFont.boldSystemFont(ofSize: size))

            case "p", "div":
                content = attributedString(element: childElement, documentBody: documentBody, preserveFormatting: preserveFormatting, listTag: listTag, listIndex: &childIndex, indentLevel: indentLevel)
                content.append(NSAttributedString(string: "\n"))
                
            case "br":
                content = NSMutableAttributedString(string: "\n")
                
            case "b", "strong":
                content = attributedString(element: childElement, documentBody: documentBody, preserveFormatting: preserveFormatting, listTag: listTag, listIndex: &childIndex, indentLevel: indentLevel)
                content.setFontPreservingSymbolicTraits(UIFont.boldSystemFont(ofSize: fontPointSize))
                
            case "i", "em":
                content = attributedString(element: childElement, documentBody: documentBody, preserveFormatting: preserveFormatting, listTag: listTag, listIndex: &childIndex, indentLevel: indentLevel)
                content.setFontPreservingSymbolicTraits(UIFont.italicSystemFont(ofSize: fontPointSize))
                
            case "u":
                content = attributedString(element: childElement, documentBody: documentBody, preserveFormatting: preserveFormatting, listTag: listTag, listIndex: &childIndex, indentLevel: indentLevel)
                content.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: content.length))
                
            case "s", "del":
                content = attributedString(element: childElement, documentBody: documentBody, preserveFormatting: preserveFormatting, listTag: listTag, listIndex: &childIndex, indentLevel: indentLevel)
                content.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: content.length))
                
            case "sup":
                content = attributedString(element: childElement, documentBody: documentBody, preserveFormatting: preserveFormatting, listTag: listTag, listIndex: &childIndex, indentLevel: indentLevel)
                content.addAttribute(.baselineOffset, value: 6, range: NSRange(location: 0, length: content.length))
                content.setFontPreservingSymbolicTraits(UIFont.systemFont(ofSize: fontPointSize * 0.7))
                
            case "sub":
                content = attributedString(element: childElement, documentBody: documentBody, preserveFormatting: preserveFormatting, listTag: listTag, listIndex: &childIndex, indentLevel: indentLevel)
                content.addAttribute(.baselineOffset, value: -4, range: NSRange(location: 0, length: content.length))
                content.setFontPreservingSymbolicTraits(UIFont.systemFont(ofSize: fontPointSize * 0.7))
                
            case "blockquote":
                content = attributedString(element: childElement, documentBody: documentBody, preserveFormatting: preserveFormatting, listTag: listTag, listIndex: &childIndex, indentLevel: indentLevel)
                content.addAttribute(.MatrixBlockquote, value: true, range: NSRange(location: 0, length: content.length))
                
            case "code", "pre":
                let preserveFormatting = preserveFormatting || tag == "pre"
                content = attributedString(element: childElement, documentBody: documentBody, preserveFormatting: preserveFormatting, listTag: listTag, listIndex: &childIndex, indentLevel: indentLevel)
                
                let fontPointSize = fontPointSize * 0.9 // Intentionally shrink code blocks by 10%
                content.setFontPreservingSymbolicTraits(UIFont.monospacedSystemFont(ofSize: fontPointSize, weight: .regular))
                
                content.addAttribute(.CodeBlock, value: true, range: NSRange(location: 0, length: content.length))
                content.addAttribute(.backgroundColor, value: UIColor.compound._bgCodeBlock as Any, range: NSRange(location: 0, length: content.length))
                
                // Don't allow identifiers or links in code blocks
                content.removeAttribute(.MatrixRoomID, range: NSRange(location: 0, length: content.length))
                content.removeAttribute(.MatrixRoomAlias, range: NSRange(location: 0, length: content.length))
                content.removeAttribute(.MatrixUserID, range: NSRange(location: 0, length: content.length))
                content.removeAttribute(.MatrixEventOnRoomID, range: NSRange(location: 0, length: content.length))
                content.removeAttribute(.MatrixEventOnRoomAlias, range: NSRange(location: 0, length: content.length))
                content.removeAttribute(.MatrixAllUsersMention, range: NSRange(location: 0, length: content.length))
                content.removeAttribute(.link, range: NSRange(location: 0, length: content.length))
                
            case "hr":
                content = NSMutableAttributedString(string: "\n")
                
            case "a":
                content = attributedString(element: childElement, documentBody: documentBody, preserveFormatting: preserveFormatting, listTag: listTag, listIndex: &childIndex, indentLevel: indentLevel)
                if let href = try? childElement.attr("href"), let url = URL(string: href) {
                    content.addAttribute(.link, value: url, range: NSRange(location: 0, length: content.length))
                }
                
            case "span":
                if childElement.dataset()[Self.attributeMSC4286] == nil {
                    content = attributedString(element: childElement, documentBody: documentBody, preserveFormatting: preserveFormatting, listTag: listTag, listIndex: &childIndex, indentLevel: indentLevel)
                }
                
            case "ul", "ol":
                var listIndex = 1
                if let startAttribute = try? childElement.attr("start"), let startIndex = Int(startAttribute) {
                    listIndex = startIndex
                }
                
                content = attributedString(element: childElement, documentBody: documentBody, preserveFormatting: preserveFormatting, listTag: tag, listIndex: &listIndex, indentLevel: indentLevel + 1)
                
                if indentLevel > 0 {
                    content.insert(NSAttributedString("\n"), at: 0)
                }

            case "li":
                var bullet = String(repeating: "  ", count: indentLevel)
                if listTag == "ol" {
                    bullet += "\(listIndex). "
                    listIndex += 1
                } else {
                    bullet += "• "
                }
                
                content = attributedString(element: childElement, documentBody: documentBody, preserveFormatting: preserveFormatting, listTag: listTag, listIndex: &childIndex, indentLevel: indentLevel + 1)
                content.insert(NSAttributedString(string: bullet), at: 0)
                if !(content.string.last?.isNewline ?? false) {
                    content.append(NSAttributedString(string: "\n"))
                }
                
            case "img":
                if let alt = try? childElement.attr("alt"), !alt.isEmpty {
                    content = NSMutableAttributedString(string: "[img: \(alt)]")
                } else {
                    content = NSMutableAttributedString(string: "[img]")
                }
                
            default:
                content = attributedString(element: childElement, documentBody: documentBody, preserveFormatting: preserveFormatting, listTag: listTag, listIndex: &childIndex, indentLevel: indentLevel)
            }
            
            result.append(content)
        }
        
        return result
    }
    
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
    
    // swiftlint:disable:next cyclomatic_complexity
    private func addLinksAndMentions(_ attributedString: NSMutableAttributedString) {
        let string = attributedString.string
        
        // Event identifiers and room aliases and identifiers detected in plain text are techincally incomplete
        // without via parameters and we won't bother detecting them
        
        var matches: [TextParsingMatch] = MatrixEntityRegex.userIdentifierRegex.matches(in: string).compactMap { match in
            guard let matchRange = Range(match.range, in: string) else {
                return nil
            }
            
            let identifier = String(string[matchRange])

            return TextParsingMatch(type: .userID(identifier: identifier), range: match.range)
        }
        
        matches.append(contentsOf: MatrixEntityRegex.roomAliasRegex.matches(in: string).compactMap { match in
            guard let matchRange = Range(match.range, in: string) else {
                return nil
            }
            
            let alias = String(string[matchRange])
            
            return TextParsingMatch(type: .roomAlias(alias: alias), range: match.range)
        })
        
        matches.append(contentsOf: MatrixEntityRegex.uriRegex.matches(in: string).compactMap { match in
            guard let matchRange = Range(match.range, in: string) else {
                return nil
            }
            
            let uri = String(string[matchRange])
            
            return TextParsingMatch(type: .matrixURI(uri: uri), range: match.range)
        })
        
        matches.append(contentsOf: MatrixEntityRegex.linkRegex.matches(in: string).compactMap { match in
            guard let matchRange = Range(match.range, in: string), let url = match.url else {
                return nil
            }
            
            // If the NSDataDetector found a hyperlink then sanitise it
            if url.scheme?.contains("http") ?? false {
                // Use the underlying string so it gets an `https` scheme if it didn't have any
                return TextParsingMatch(type: .link(urlString: String(string[matchRange]).asSanitizedLink), range: match.range)
            } else { // otherwise use it as it is e.g. mailto: (https://github.com/element-hq/element-x-ios/issues/4913)
                return TextParsingMatch(type: .link(urlString: url.absoluteString), range: match.range)
            }
        })
        
        matches.append(contentsOf: MatrixEntityRegex.allUsersRegex.matches(in: attributedString.string).map { match in
            TextParsingMatch(type: .atRoom, range: match.range)
        })
        
        guard matches.count > 0 else {
            return
        }
        
        // Sort the links by length so the longest one always takes priority
        matches.sorted { $0.range.length > $1.range.length }.forEach { [attributedString] match in
            // Don't highlight links within codeblocks
            let isInCodeBlock = attributedString.attribute(.CodeBlock, at: match.range.location, effectiveRange: nil) != nil
            if isInCodeBlock {
                return
            }
            
            var hasLink = false
            attributedString.enumerateAttribute(.link, in: match.range, options: []) { value, _, stop in
                if value != nil, !isInCodeBlock {
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
            case .roomAlias(let alias):
                if let urlString = try? matrixToRoomAliasPermalink(roomAlias: alias),
                   let url = URL(string: urlString) {
                    attributedString.addAttribute(.link, value: url, range: match.range)
                }
            case .matrixURI(let uri):
                if let url = URL(string: uri) {
                    attributedString.addAttribute(.link, value: url, range: match.range)
                }
            case .userID, .link:
                if let url = match.link {
                    attributedString.addAttribute(.link, value: url, range: match.range)
                }
            }
        }
    }
    
    func addMatrixEntityPermalinkAttributesTo(_ attributedString: NSMutableAttributedString) {
        attributedString.enumerateAttribute(.link, in: .init(location: 0, length: attributedString.length), options: []) { value, range, _ in
            if value != nil {
                if let url = value as? URL,
                   let matrixEntity = parseMatrixEntityFrom(uri: url.absoluteString) {
                    switch matrixEntity.id {
                    case .user(let userID):
                        mentionBuilder.handleUserMention(for: attributedString, in: range, url: url, userID: userID, userDisplayName: nil)
                    case .room(let roomID):
                        mentionBuilder.handleRoomIDMention(for: attributedString, in: range, url: url, roomID: roomID)
                    case .roomAlias(let alias):
                        mentionBuilder.handleRoomAliasMention(for: attributedString, in: range, url: url, roomAlias: alias, roomDisplayName: nil)
                    case .eventOnRoomId(let roomID, let eventID):
                        mentionBuilder.handleEventOnRoomIDMention(for: attributedString, in: range, url: url, eventID: eventID, roomID: roomID)
                    case .eventOnRoomAlias(let alias, let eventID):
                        mentionBuilder.handleEventOnRoomAliasMention(for: attributedString, in: range, url: url, eventID: eventID, roomAlias: alias)
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
        
    private func detectPhishingAttempts(_ attributedString: NSMutableAttributedString) {
        attributedString.enumerateAttribute(.link, in: .init(location: 0, length: attributedString.length), options: []) { value, range, _ in
            guard value != nil, let internalURL = value as? URL else {
                return
            }
            let displayString = attributedString.attributedSubstring(from: range).string
            
            guard PhishingDetector.isPhishingAttempt(displayString: displayString, internalURL: internalURL) else {
                return
            }
            handlePhishingAttempt(for: attributedString, in: range, internalURL: internalURL, displayString: displayString)
        }
    }
    
    private func handlePhishingAttempt(for attributedString: NSMutableAttributedString,
                                       in range: NSRange,
                                       internalURL: URL,
                                       displayString: String) {
        // Let's remove the existing link attribute
        attributedString.removeAttribute(.link, range: range)
        
        var urlComponents = URLComponents()
        urlComponents.scheme = URL.confirmationScheme
        urlComponents.host = ""
        let parameters = ConfirmURLParameters(internalURL: internalURL, displayString: displayString)
        urlComponents.queryItems = parameters.urlQueryItems
        
        guard let finalURL = urlComponents.url else {
            return
        }
        
        attributedString.addAttribute(.link, value: finalURL, range: range)
    }
    
    private func removeParsingArtefacts(_ attributedString: NSMutableAttributedString) {
        guard attributedString.length > 0 else {
            return
        }
        
        // Ruma's markdown parsing sometimes inserts extra trailing new lines
        // https://github.com/ruma/ruma/blob/c3dc6de3e03b2ca131eab889a9d310ef160b95ac/crates/ruma-events/src/room/message.rs#L962
        while (attributedString.string as NSString).hasSuffixCharacter(from: .whitespacesAndNewlines) {
            attributedString.deleteCharacters(in: .init(location: attributedString.length - 1, length: 1))
        }
    }
}

private struct TextParsingMatch {
    enum MatchType {
        case userID(identifier: String)
        case roomAlias(alias: String)
        case matrixURI(uri: String)
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

private extension NSMutableAttributedString {
    func setFontPreservingSymbolicTraits(_ newFont: UIFont) {
        enumerateAttribute(.font, in: NSRange(location: 0, length: length)) { value, range, _ in
            if let oldFont = value as? UIFont {
                // keep the traits (bold, italic, etc.)
                let traits = oldFont.fontDescriptor.symbolicTraits
                if let descriptor = newFont.fontDescriptor.withSymbolicTraits(traits) {
                    let updatedFont = UIFont(descriptor: descriptor, size: newFont.pointSize)
                    addAttribute(.font, value: updatedFont, range: range)
                } else {
                    // fallback if traits can't be applied
                    addAttribute(.font, value: newFont, range: range)
                }
            } else {
                addAttribute(.font, value: newFont, range: range)
            }
        }
    }
}

private extension NSString {
    func hasSuffixCharacter(from characterSet: CharacterSet) -> Bool {
        if length == 0 {
            return false
        }
        
        let lastChar = character(at: length - 1)
        
        return (characterSet as NSCharacterSet).characterIsMember(lastChar)
    }
}
