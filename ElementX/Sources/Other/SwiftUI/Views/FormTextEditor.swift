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

struct FormTextEditor: View {
    @Binding var text: String
    let placeholder: String
    var editorAccessibilityIdentifier: String?

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.element.formRowBackground)

            let textEditor = TextEditor(text: $text)
                .tint(.element.brand)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .cornerRadius(14)
                .scrollContentBackground(.hidden)
            if let editorAccessibilityIdentifier {
                textEditor
                    .accessibilityIdentifier(editorAccessibilityIdentifier)
            } else {
                textEditor
            }

            if text.isEmpty {
                Text(placeholder)
                    .font(.element.body)
                    .foregroundColor(Color.element.secondaryContent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.element.quaternaryContent)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .font(.body)
    }
}

struct FormTextEditor_Previews: PreviewProvider {
    static var previews: some View {
        FormTextEditor(text: .constant(""), placeholder: "test", editorAccessibilityIdentifier: nil)
    }
}
