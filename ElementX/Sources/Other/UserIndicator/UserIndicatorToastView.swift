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

struct UserIndicatorToastView_Previews: PreviewProvider {
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
