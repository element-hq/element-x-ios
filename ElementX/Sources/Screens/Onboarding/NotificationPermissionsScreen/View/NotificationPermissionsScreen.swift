//
// Copyright 2021 New Vector Ltd
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

/// A prompt that asks the user whether they would like to enable Analytics or not.
struct NotificationPermissionsScreen: View {
    @ObservedObject var context: NotificationPermissionsScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog(topPadding: UIConstants.startScreenBreakerScreenTopPadding) {
            mainContent
        } bottomContent: {
            buttons
        }
        .background()
        .environment(\.backgroundStyle, AnyShapeStyle(Color.compound.bgCanvasDefault))
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
    
    /// The main content of the screen that is shown inside the scroll view.
    private var mainContent: some View {
        VStack(spacing: 8) {
            HeroImage(icon: \.notificationsSolid)
                .padding(.bottom, 8)
            
            #warning("FIXME")
            Text("Allow notifications and never miss a message")
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
            
            #warning("FIXME")
            Text("You can change your settings later.")
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
        }
    }

    private var buttons: some View {
        VStack(spacing: 16) {
            Button { context.send(viewAction: .enable) } label: {
                Text(L10n.actionOk)
                    .font(.compound.bodyLGSemibold)
            }
            .buttonStyle(.compound(.primary))
            
            Button { context.send(viewAction: .notNow) } label: {
                Text(L10n.actionNotNow)
                    .font(.compound.bodyLGSemibold)
                    .padding(14)
            }
        }
    }
}

// MARK: - Previews

struct NotificationPermissionsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = NotificationPermissionsScreenViewModel(notificationManager: NotificationManagerMock())
    static var previews: some View {
        NotificationPermissionsScreen(context: viewModel.context)
    }
}
