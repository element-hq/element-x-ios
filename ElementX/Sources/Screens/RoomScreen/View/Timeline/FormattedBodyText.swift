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

import Foundation
import SwiftUI

struct FormattedBodyText: View {
    @Environment(\.timelineStyle) private var timelineStyle
    
    let attributedComponents: [AttributedStringBuilderComponent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            ForEach(attributedComponents, id: \.self) { component in
                if component.isBlockquote {
                    if timelineStyle == .plain {
                        HStack(spacing: 4.0) {
                            Rectangle()
                                .foregroundColor(Color.red)
                                .frame(width: 4.0)
                            richText(from: component.attributedString)
                                .foregroundColor(.element.primaryContent)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    } else {
                        richText(from: component.attributedString.mergingAttributes(blockquoteAttributes))
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(.element.primaryContent)
                            .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                            .clipped()
                            .background(Color.element.systemGray4)
                            .cornerRadius(13)
                    }
                } else {
                    richText(from: component.attributedString)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.element.primaryContent)
                }
            }
        }
        .tint(.element.links)
    }

    private var blockquoteAttributes: AttributeContainer {
        var container = AttributeContainer()
        container.font = .element.caption1
        return container
    }
    
    @MainActor
    private func richText(from attributedString: AttributedString) -> Text {
        var richText = Text("")
        attributedString.runs.forEach { run in
            guard let userId = run.userId else {
                richText = richText + Text(AttributedString(attributedString[run.range]))
                return
            }
            
            // TODO: replace the userId by the user displayname when available
            let pillView = pill(forUser: userId)
            let pillImage = ImageRenderer(content: pillView)
            pillImage.scale = 3
            
            guard let image = pillImage.uiImage else {
                richText = richText + Text(AttributedString(attributedString[run.range]))
                return
            }
            
            richText = richText + Text(Image(uiImage: image))
        }
        return richText
    }
    
    private func pill(forUser user: String) -> some View {
        // TODO: We could replace this Text by Label with the avatar as image
        Text(user)
            .foregroundColor(Color.element.background)
            .font(.element.caption1)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 2)
        // TODO: adapt the color accordingly to the userId of the current sesson
            .background(Capsule().fill(Color.element.alert))
    }
}

extension FormattedBodyText {
    init(text: String) {
        attributedComponents = [.init(attributedString: AttributedString(text), isBlockquote: false)]
    }
}

struct FormattedBodyText_Previews: PreviewProvider {
    static var previews: some View {
        body
        body.timelineStyle(.plain)
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
            <a href=\"https://matrix.to/#/@userId:matrix.org\">User</a>: some text
            <blockquote><a href=\"https://matrix.to/#/@userId:matrix.org\">User</a>: some text</blockquote>
            @userId:matrix.org: some text
            """,
            """
            <code>Hello world</code>
            <p>Text</p>
            <code><b>Hello</b> <i>world</i></code>
            <p>Text</p>
            <code>Hello world</code>
            """
        ]
        
        let attributedStringBuilder = AttributedStringBuilder()
        
        VStack(alignment: .leading, spacing: 24.0) {
            ForEach(htmlStrings, id: \.self) { htmlString in
                let attributedString = attributedStringBuilder.fromHTML(htmlString)
                
                if let components = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedString) {
                    FormattedBodyText(attributedComponents: components)
                        .fixedSize()
                }
            }
            FormattedBodyText(text: "Some plain text that's not an attributed component.")
            FormattedBodyText(text: "@userId:matrix.org plain text that's not an attributed component.")
        }
    }
}
