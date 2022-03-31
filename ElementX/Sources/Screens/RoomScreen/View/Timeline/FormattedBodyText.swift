//
//  FormattedBodyText.swift
//  ElementX
//
//  Created by Stefan Ceriu on 24/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

struct FormattedBodyText: View {
    let attributedComponents: [AttributedStringBuilderComponent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            ForEach(attributedComponents, id: \.self) { component in
                if component.isBlockquote {
                    HStack(spacing: 4.0) {
                        Rectangle()
                            .foregroundColor(Color.red)
                            .frame(width: 4.0)
                        Text(component.attributedString)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text(component.attributedString)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(.elementGreen)
    }
}

struct FormattedBodyText_Previews: PreviewProvider {
    static var previews: some View {
        body
        body.preferredColorScheme(.dark)
        
    }
    
    @ViewBuilder
    static var body: some View {
        let htmlStrings = [
"""
Text before blockquote
<blockquote>
<b>bold</b> <i>italic</i>
</blockquote>
Text after blockquote
""",
"""
<blockquote>First blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
<blockquote>Second blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
<blockquote>Third blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
""",
"""
<code>Hello world</code>
<p>Text</p>
<code><b>Hello</b> <i>world</i></code>
<p>Text</p>
<code>Hello world</code>
"""]
        
        let attributedStringBuilder = AttributedStringBuilder()
        VStack(alignment: .leading, spacing: 24.0) {
            ForEach(htmlStrings, id: \.self) { htmlString in
                let attributedString = attributedStringBuilder.fromHTML(htmlString)
                
                if let components = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedString) {
                    FormattedBodyText(attributedComponents: components)
                        .fixedSize()
                }
            }
        }
    }
}
