//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct UserIndicatorModalView: View {
    let indicator: UserIndicator
    @State private var progressFraction = 0.0

    var body: some View {
        ZStack {
            VStack(spacing: 12.0) {
                if case .indeterminate = indicator.progress {
                    ProgressView()
                } else if case .published = indicator.progress {
                    ProgressView(value: progressFraction)
                }

                HStack(spacing: 8) {
                    if let iconName = indicator.iconName {
                        Image(systemName: iconName)
                            .font(.compound.bodyLG)
                            .foregroundColor(.compound.iconPrimary)
                    }
                    Text(indicator.title)
                        .font(.compound.bodyLG)
                        .foregroundColor(.compound.textPrimary)
                }
            }
            .padding()
            .frame(minWidth: 150.0)
            .fixedSize(horizontal: true, vertical: false)
            .background(Color.compound.bgSubtlePrimary)
            .clipShape(RoundedCornerShape(radius: 12.0, corners: .allCorners))
            .shadow(color: .black.opacity(0.1), radius: 10.0, y: 4.0)
            .onReceive(indicator.progressPublisher) { progress in
                progressFraction = progress
            }
            .transition(.opacity)
        }
        .id(indicator.id)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if !indicator.allowsInteraction {
                Color.black.opacity(0.1)
            }
        }
        .ignoresSafeArea()
        .interactiveDismissDisabled(indicator.interactiveDismissDisabled)
    }
}

struct UserIndicatorModalView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        Group {
            UserIndicatorModalView(indicator: UserIndicator(type: .modal,
                                                            title: "Successfully logged in",
                                                            iconName: "checkmark")
            )
            .previewDisplayName("Spinner")
            
            UserIndicatorModalView(indicator: UserIndicator(type: .modal(progress: .published(CurrentValueSubject<Double, Never>(0.5).asCurrentValuePublisher()),
                                                                         interactiveDismissDisabled: false,
                                                                         allowsInteraction: false),
                                                            title: "Successfully logged in",
                                                            iconName: "checkmark")
            )
            .previewDisplayName("Progress Bar")
            
            UserIndicatorModalView(indicator: UserIndicator(type: .modal(progress: .none,
                                                                         interactiveDismissDisabled: false,
                                                                         allowsInteraction: false),
                                                            title: "Successfully logged in",
                                                            iconName: "checkmark")
            )
            .previewDisplayName("No progress")
        }
    }
}
