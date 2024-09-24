//
// Copyright 2024 New Vector Ltd
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

struct VerifyLoginScreen: View {
    
    @ObservedObject var context: IdentityConfirmationScreenViewModel.Context
    
    @State var isShowingDismissAlert = false
    
    var body: some View {
        FullscreenDialog(topPadding: 0, horizontalPadding: 0) {
            header
            
            content
        } bottomContent: {
            actionButton
        }
        .background()
        .backgroundStyle(Asset.Colors.zeroDarkGrey.swiftUIColor)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled()     
        .alert("Are you sure?", isPresented: $isShowingDismissAlert, actions: {
            Button("Return", role: .cancel) { }
            Button("Verify later", role: .destructive) {
                context.send(viewAction: .skip)
            }
        }, message: {
            Text("You have not verified this login, messages from past conversations may be hidden.")
                .font(.zero.bodySM)
        })
    }
    
    var header: some View {
        Image(asset: Asset.Images.zeroBackupHeader)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 192)
            .overlay(alignment: .topTrailing) {
                Button {
                    self.isShowingDismissAlert = true
                } label: {
                    Image(asset: Asset.Images.crossIcon)
                        .foregroundStyle(Color.white)
                        .frame(width: 32, height: 32)
                }
                .padding([.top, .trailing], 16)
            }
    }
    
    var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Verify Login")
                .font(.zero.bodyLG)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                .padding(.top, 24)
            
            Text("It looks like this is a new device or login for your account. Enter your account backup phrase to see past messages.")
                .multilineTextAlignment(.leading)
                .font(.zero.bodySM)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
            
            Button {
            } label: {
                HStack {
                    Text("Learn more")
                        .foregroundStyle(Asset.Colors.blue11.swiftUIColor)
                        .font(.zero.bodySM)
                    
                    Image(systemName: "arrow.right")
                        .foregroundStyle(Asset.Colors.blue11.swiftUIColor)
                        .font(.inter(size: 10))
                }
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(asset: Asset.Images.checkIcon)
                        .foregroundStyle(Asset.Colors.blue11.swiftUIColor)
                    
                    Text("Your account has a backup phrase")
                        .foregroundStyle(Asset.Colors.blue11.swiftUIColor)
                        .font(.zero.bodySM)
                }
                
                HStack(alignment: .top) {
                    Image(asset: Asset.Images.alertCircleIcon)
                        .foregroundStyle(Asset.Colors.textWarning.swiftUIColor)
                    
                    Text("Your current login is not verified, some message history may be hidden.")
                        .foregroundStyle(Asset.Colors.textWarning.swiftUIColor)
                        .font(.zero.bodySM)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    var actionButton: some View {
        Button {
            context.send(viewAction: .recoveryKey)
        } label: {
            Text("Verify with backup phrase")
                .font(.zero.bodyMDSemibold)
                .foregroundStyle(Asset.Colors.blue11.swiftUIColor)
                .frame(height: 48)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.99, green: 0.99, blue: 0.99).opacity(0.05))
                .cornerRadius(9999)
                .overlay(
                    RoundedRectangle(cornerRadius: 9999)
                        .inset(by: 0.5)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 44)
        .padding(.horizontal, 32)
    }
}

// MARK: - Previews

struct VerifyLoginScreen_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        NavigationStack {
            VerifyLoginScreen(context: viewModel.context)
        }
        .snapshot(delay: 0.25)
    }
    
    private static var viewModel: IdentityConfirmationScreenViewModel {
        let clientProxy = ClientProxyMock(.init())
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        userSession.sessionSecurityStatePublisher = CurrentValuePublisher<SessionSecurityState, Never>(.init(verificationState: .unverified, recoveryState: .enabled))
        
        return IdentityConfirmationScreenViewModel(userSession: userSession,
                                                   appSettings: ServiceLocator.shared.settings,
                                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
