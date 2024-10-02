//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct UserIndicatorToastView: View {
    let indicator: UserIndicator
    
    var body: some View {
        HStack(spacing: 4) {
            if case .indeterminate = indicator.progress {
                ProgressView()
                    .controlSize(.small)
                    .tint(.compound.iconPrimary)
            }
            if let iconName = indicator.iconName {
                Image(systemName: iconName)
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.iconPrimary)
            }
            Text(indicator.title)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
        }
        .id(indicator.id)
        .padding(.horizontal, 12.0)
        .padding(.vertical, 10.0)
        .background(Color.compound.bgSubtlePrimary)
        .clipShape(RoundedCornerShape(radius: 24.0, corners: .allCorners))
        .shadow(color: .black.opacity(0.1), radius: 6.0, y: 4.0)
        .transition(toastTransition)
    }
    
    private var toastTransition: AnyTransition {
        AnyTransition
            .asymmetric(insertion: .move(edge: .top),
                        removal: .move(edge: .bottom))
            .combined(with: .opacity)
    }
}

struct UserIndicatorToastView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 30) {
            UserIndicatorToastView(indicator: UserIndicator(title: "Successfully logged in",
                                                            iconName: "checkmark"))
            
            UserIndicatorToastView(indicator: UserIndicator(title: "Toast without icon"))
            
            UserIndicatorToastView(indicator: UserIndicator(type: .toast(progress: .indeterminate),
                                                            title: "Syncing"))
        }
    }
}
