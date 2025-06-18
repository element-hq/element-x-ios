//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct AppForceUpdateScreen: View {
    var body: some View {
        VStack {
            Spacer()
            
            VStack {
                Image(asset: Asset.Images.imgAppUpdate)
                
                Text("Update Required")
                    .font(.compound.headingMDBold)
                    .foregroundColor(.zero.bgAccentRest)
                    .padding(.top, 12)
                
                Text("To continue using the app, please update to the latest version.")
                    .font(.zero.bodyLG)
                    .foregroundColor(.compound.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 1)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: {
                openAppStore()
            }) {
                Text("Update Now")
                    .font(.compound.bodyMDSemibold)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.zero.bgAccentRest)
                    )
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.zero.bgCanvasDefault)
    }
    
    private func openAppStore() {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/\(ZeroContants.ZERO_APP_STORE_APP_ID)") {
            UIApplication.shared.open(url)
        }
    }
}
