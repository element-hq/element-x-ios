//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import LRUCache
import MatrixRustSDK
import SwiftSoup
import UIKit

struct AttributedStringBuilderV2: AttributedStringBuilderProtocol {
    private let cacheKey: String
    private let mentionBuilder: MentionBuilderProtocol
    
    private static let attributeMSC4286 = "data-msc4286-external-payment-details"
    private static let cacheDispatchQueue = DispatchQueue(label: "io.element.elementx.attributed_string_builder_v2_cache")
    private static var caches: [String: LRUCache<String, AttributedString>] = [:]

    static func invalidateCaches() {
        caches.removeAll()
    }
    
    init(cacheKey: String, mentionBuilder: MentionBuilderProtocol) {
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
        
        let mutableAttributedString = attributedString(from: body, preserveFormatting: false)
        detectPhishingAttempts(mutableAttributedString)
        addLinksAndMentions(mutableAttributedString)
        addMatrixEntityPermalinkAttributesTo(mutableAttributedString)
        
        let result = try? AttributedString(mutableAttributedString, including: \.elementX)
        Self.cacheValue(result, forKey: htmlString, cacheKey: cacheKey)
        
        return result
    }
    
    // MARK: - Private
    
    func attributedString(from element: Element, preserveFormatting: Bool) -> NSMutableAttributedString {
        let result = NSMutableAttributedString()
        
        for node in element.getChildNodes() {
            if let textNode = node as? TextNode {
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
            
            switch tag {
            case "h1", "h2", "h3", "h4", "h5", "h6":
                let level = Int(String(tag.dropFirst())) ?? 1
                let size: CGFloat = UIFont.systemFontSize + CGFloat(6 - level) * 2
                content = attributedString(from: childElement, preserveFormatting: preserveFormatting)
                content.setFontPreservingSymbolicTraits(UIFont.boldSystemFont(ofSize: size))
                
            case "p", "div":
                content = attributedString(from: childElement, preserveFormatting: preserveFormatting)
                content.append(NSAttributedString(string: "\n"))
                
            case "br":
                content = NSMutableAttributedString(string: "\n")
                
            case "b", "strong":
                content = attributedString(from: childElement, preserveFormatting: preserveFormatting)
                content.setFontPreservingSymbolicTraits(UIFont.boldSystemFont(ofSize: UIFont.systemFontSize))
                
            case "i", "em":
                content = attributedString(from: childElement, preserveFormatting: preserveFormatting)
                content.setFontPreservingSymbolicTraits(UIFont.italicSystemFont(ofSize: UIFont.systemFontSize))
                
            case "u":
                content = attributedString(from: childElement, preserveFormatting: preserveFormatting)
                content.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: content.length))
                
            case "s", "del":
                content = attributedString(from: childElement, preserveFormatting: preserveFormatting)
                content.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: content.length))
                
            case "sup":
                content = attributedString(from: childElement, preserveFormatting: preserveFormatting)
                content.addAttribute(.baselineOffset, value: 6, range: NSRange(location: 0, length: content.length))
                content.setFontPreservingSymbolicTraits(UIFont.systemFont(ofSize: UIFont.systemFontSize * 0.7))
                
            case "sub":
                content = attributedString(from: childElement, preserveFormatting: preserveFormatting)
                content.addAttribute(.baselineOffset, value: -4, range: NSRange(location: 0, length: content.length))
                content.setFontPreservingSymbolicTraits(UIFont.systemFont(ofSize: UIFont.systemFontSize * 0.7))
                
            case "blockquote":
                content = attributedString(from: childElement, preserveFormatting: preserveFormatting)
                content.addAttribute(.MatrixBlockquote, value: true, range: NSRange(location: 0, length: content.length))
                
            case "code", "pre":
                let preserveFormatting = preserveFormatting || tag == "pre"
                content = attributedString(from: childElement, preserveFormatting: preserveFormatting)
                content.setFontPreservingSymbolicTraits(UIFont.monospacedSystemFont(ofSize: UIFont.systemFontSize, weight: .regular))
                content.addAttribute(.backgroundColor, value: UIColor.compound._bgCodeBlock as Any, range: NSRange(location: 0, length: content.length))
                
            case "hr":
                content = NSMutableAttributedString(string: "\n")
                
            case "a":
                content = attributedString(from: childElement, preserveFormatting: preserveFormatting)
                if let href = try? childElement.attr("href") {
                    content.addAttribute(.link, value: href, range: NSRange(location: 0, length: content.length))
                }
                
            case "span":
                if (try? childElement.attr(Self.attributeMSC4286)) ?? nil != nil {
                    content = attributedString(from: childElement, preserveFormatting: preserveFormatting)
                }
                
            default:
                content = attributedString(from: childElement, preserveFormatting: preserveFormatting)
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
            guard let matchRange = Range(match.range, in: string) else {
                return nil
            }
            
            let link = String(string[matchRange]).asSanitizedLink
            return TextParsingMatch(type: .link(urlString: link), range: match.range)
        })
        
        matches.append(contentsOf: MatrixEntityRegex.allUsersRegex.matches(in: attributedString.string).map { match in
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
