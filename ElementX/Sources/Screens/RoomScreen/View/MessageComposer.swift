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

import SwiftUI

struct MessageComposer: View {
    @Binding var text: String
    var disabled: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(alignment: .bottom) {
            MessageComposerTextField(placeholder: "Send a message", text: $text, maxHeight: 300)
            Button {
                action()
            } label: {
                Image(uiImage: Asset.Images.timelineComposerSendMessage.image)
                    .background(Circle()
                        .foregroundColor(.global.white)
                        .padding(2)
                    )
            }
            .padding(.bottom, 6.0)
            .disabled(disabled)
            .opacity(disabled ? 0.5 : 1.0)
            .animation(.default, value: disabled)
            .keyboardShortcut(.return, modifiers: [.command])
        }
    }
}

struct MessageComposer_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        VStack {
            MessageComposer(text: .constant(""), disabled: true) { }
            MessageComposer(text: .constant("Some message"), disabled: false) { }
        }
        .tint(.element.accent)
    }
}
