//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

/// The screen shown at the beginning of the onboarding flow.
struct CompleteProfileScreen: View {
    @ObservedObject var context: CompleteProfileScreenViewModel.Context
    
    var body: some View {
        VStack {
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(ZeroAuthBackgroundModifier())
        .navigationTitle("Complete Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}
