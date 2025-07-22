//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

import SwiftUI

struct SwipeToConfirmButton: View {
    let onConfirm: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isConfirmed = false
    
    private let buttonHeight: CGFloat = 56
    private let knobSize: CGFloat = 56
    private let horizontalPadding: CGFloat = 16
    
    var body: some View {
        GeometryReader { geometry in
            let fullWidth = geometry.size.width - 2 * horizontalPadding
            let maxOffset = fullWidth - knobSize
            let threshold = maxOffset

            ZStack {
                RoundedRectangle(cornerRadius: buttonHeight / 4)
                    .stroke(.zero.bgAccentRest, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: buttonHeight / 4)
                            .fill(.zero.bgAccentRest.opacity(0.15))
                    )
                    .frame(height: buttonHeight)

                Text(isConfirmed ? "Confirmed" : "Swipe to Confirm")
                    .foregroundColor(.zero.bgAccentRest)
                    .font(.compound.bodyLGSemibold)
                    .opacity(isConfirmed ? 1.0 : max(0, 1.0 - (dragOffset / threshold)))

                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: knobSize / 4)
                            .fill(.zero.bgAccentRest)
                            .frame(width: knobSize, height: knobSize)

                        Image(systemName: isConfirmed ? "checkmark" : "chevron.right")
                            .foregroundColor(.black)
                            .font(.system(size: 20, weight: .bold))
                    }
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                guard !isConfirmed else { return }
                                dragOffset = max(0, min(value.translation.width, maxOffset))
                            }
                            .onEnded { _ in
                                guard !isConfirmed else { return }
                                if dragOffset >= threshold {
                                    withAnimation {
                                        dragOffset = maxOffset
                                        isConfirmed = true
                                        onConfirm()
                                        let generator = UINotificationFeedbackGenerator()
                                        generator.notificationOccurred(.success)
                                    }
                                } else {
                                    withAnimation {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )

                    Spacer()
                }
//                .padding(.horizontal, horizontalPadding)
            }
            .frame(height: buttonHeight)
            .padding(.horizontal, horizontalPadding)
        }
        .frame(height: buttonHeight + 8) // Give GeometryReader a height
    }
}
