//
//  MessageComposer.swift
//  ElementX
//
//  Created by Stefan Ceriu on 15/04/2022.
//  Copyright © 2022 Element. All rights reserved.
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
            .animation(.elementDefault, value: disabled)
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
