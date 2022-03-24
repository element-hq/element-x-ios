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
    
    private var defaultCSS: String {
        AttributedStringBuilderUtils.cssToMarkBlockquotes() +
"""
        pre,code {
            background-color: #F5F7FA;
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
        let defaultColor = UIColor.black
        
        let parsingOptions: [String: Any] = [
            DTUseiOS6Attributes: true,
            DTDefaultFontFamily: defaultFont.familyName,
            DTDefaultFontName: defaultFont.fontName,
            DTDefaultFontSize: defaultFont.pointSize,
            DTDefaultTextColor: defaultColor,
            DTDefaultLinkDecoration: false,
            DTDefaultStyleSheet: DTCSSStylesheet(styleBlock: self.defaultCSS) as Any
        ]
        
        guard let builder = DTHTMLAttributedStringBuilder(html: data, options: parsingOptions, documentAttributes: nil) else {
            return nil
        }
        
        builder.willFlushCallback = { element in
            element?.sanitize(font: defaultFont)
        }
            
        guard var nsAttributedString = builder.generatedAttributedString() else {
            return nil
        }
        
        nsAttributedString = AttributedStringBuilderUtils.removeDTCoreTextArtifacts(nsAttributedString)
        
        nsAttributedString = AttributedStringBuilderUtils.removeMarkedBlockquotesArtifacts(nsAttributedString)
        
        return try? AttributedString(nsAttributedString, including: \.elementX)
    }
    
    func blockquoteCoalescedComponentsFrom(_ attributedString: AttributedString?) -> [AttributedStringBuilderComponent]? {
        guard let attributedString = attributedString else {
            return nil
        }

        return attributedString.runs[\.blockquote].map { (value, range) in
            AttributedStringBuilderComponent(attributedString: AttributedString(attributedString[range]),
                                             isBlockquote: value != nil)
        }
    }
}
