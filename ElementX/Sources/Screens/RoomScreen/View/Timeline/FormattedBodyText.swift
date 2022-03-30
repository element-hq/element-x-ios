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
        VStack(alignment: .leading, spacing: 0.0) {
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
        let htmlString = """
Text before blockquote
<blockquote>
<b>bold</b> <i>italic</i>
</blockquote>
Text after blockquote
"""
        
        let attributedStringBuilder = AttributedStringBuilder()
        let attributedString = attributedStringBuilder.fromHTML(htmlString)
        
        if let components = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedString) {
            VStack {
                FormattedBodyText(attributedComponents: components)
                    .fixedSize()
            }
        }
    }
}
