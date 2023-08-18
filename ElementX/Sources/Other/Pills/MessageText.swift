//
// Copyright 2023 New Vector Ltd
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

import SwiftUI

struct MessageText: UIViewRepresentable {
    let attributedString: AttributedString

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.isSelectable = false

        textView.contentInset = .zero
        textView.contentInsetAdjustmentBehavior = .never
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.layoutManager.usesFontLeading = false
        textView.backgroundColor = .clear
        textView.attributedText = NSAttributedString(attributedString)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = NSAttributedString(attributedString)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        uiView.sizeThatFits(CGSize(width: proposal.width ?? UIView.layoutFittingExpandedSize.width, height: UIView.layoutFittingCompressedSize.height))
    }
}

// MARK: - Previews

struct MessageText_Previews: PreviewProvider {
    static let attributedString = AttributedString("Hello World! Hello world! Hello world! Hello world! Hello World! Hellooooooooooooooooooooooo Woooooooooooooooooooooorld")
    static let attributedStringWithAttachment = "Hello " + AttributedString(NSAttributedString(attachment: PillTextAttachment(data: Data(), ofType: InfoPlistReader.main.pillsUTType))) + " World!"

    static var previews: some View {
        MessageText(attributedString: attributedString)
            .border(Color.purple)
            .previewDisplayName("Custom Text")
        // For comparison
        Text(attributedString)
            .border(Color.purple)
            .previewDisplayName("SwiftUI Default Text")
        MessageText(attributedString: attributedStringWithAttachment)
            .border(Color.purple)
            .previewDisplayName("Custom Attachment")
    }
}
