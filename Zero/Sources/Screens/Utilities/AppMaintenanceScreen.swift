//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct AppMaintenanceScreen: View {
    var body: some View {
        VStack {
            VStack {
                Image(asset: Asset.Images.imgAppMaintenance)
                
                Text("Under Maintenance")
                    .font(.compound.headingMDBold)
                    .foregroundColor(.zero.bgAccentRest)
                    .padding(.top, 12)
                
                Text("The app is under maintenance. We’ll be back soon!")
                    .font(.zero.bodyLG)
                    .foregroundColor(.compound.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 1)
            }
            .padding(.horizontal, 24)
            .padding(.top, 150)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.zero.bgCanvasDefault)
    }
}
