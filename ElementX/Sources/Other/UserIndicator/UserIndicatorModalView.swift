//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
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
                            .font(titleFont)
                            .foregroundColor(.compound.iconPrimary)
                    }
                    
                    Text(indicator.title)
                        .font(titleFont)
                        .foregroundColor(.compound.textPrimary)
                }
                
                if let message = indicator.message {
                    Text(message)
                        .font(.compound.bodyMD)
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
    
    private var titleFont: Font {
        if indicator.message != nil {
            .compound.headingMDBold
        } else {
            .compound.bodyLG
        }
    }
}

struct UserIndicatorModalView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 0) {
            UserIndicatorModalView(indicator: UserIndicator(type: .modal,
                                                            title: "Successfully logged in",
                                                            iconName: "checkmark"))
            
            UserIndicatorModalView(indicator: UserIndicator(type: .modal(progress: .published(CurrentValueSubject<Double, Never>(0.5).asCurrentValuePublisher()),
                                                                         interactiveDismissDisabled: false,
                                                                         allowsInteraction: false),
                                                            title: "Successfully logged in",
                                                            iconName: "checkmark"))
            
            UserIndicatorModalView(indicator: UserIndicator(type: .modal(progress: .none,
                                                                         interactiveDismissDisabled: false,
                                                                         allowsInteraction: false),
                                                            title: "Successfully logged in",
                                                            iconName: "checkmark"))
            
            UserIndicatorModalView(indicator: UserIndicator(type: .modal,
                                                            title: "Successfully logged in",
                                                            message: "You can now be happy.",
                                                            iconName: "checkmark"))
        }
    }
}
