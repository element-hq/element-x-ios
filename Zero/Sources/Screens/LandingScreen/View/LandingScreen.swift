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
import Combine
import Compound
import SwiftUI

struct LandingScreen: View {
    @Bindable var context: AuthenticationStartScreenViewModel.Context
    
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        HStack {
            VStack(alignment: .center) {
                if keyboardHeight <= 0 {
                    content
                    
                    actionButton
                }
                
                Spacer()
                
                createAccountSection
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: keyboardHeight / 2)
            }
        }
        .background { landingViewBackground }
        .onReceive(Publishers.keyboardHeight) { height in
            keyboardHeight = height
        }
    }
    
    var landingViewBackground: some View {
        Image(asset: Asset.Images.landingBackground)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
    
    var content: some View {
        Image(asset: Asset.Images.zeroLogoMark)
            .frame(width: 32, height: 32)
            .padding(.bottom, 70)
            .padding(.top, 60)
    }
    
    var actionButton: some View {
        Button(action: {
            context.send(viewAction: .login)
        }, label: {
            Image(asset: Asset.Images.conversationsListHeader)
                .frame(width: 358, height: 65)
        })
    }
    
    var createAccountSection: some View {
        VStack(alignment: .center) {
            Text("Create Account")
                .font(.zero.bodyLG)
                .foregroundColor(.compound.textPrimary)
                .padding(.vertical, 8)
            
            HStack(alignment: .center) {
                TextField(text: $context.inviteCode) {
                    Text("Invite Code")
                        .foregroundColor(.compound.textSecondary)
                }
                .frame(maxWidth: 200)
                .textFieldStyle(.element(accessibilityIdentifier: "create-account_invite_code"))
                .disableAutocorrection(true)
                .submitLabel(.next)
                .onSubmit {
                    if context.viewState.isInviteCodeValid {
                        context.send(viewAction: .verifyInviteCode(inviteCode: context.inviteCode))
                    }
                }
                
                Button {
                    if context.viewState.isInviteCodeValid {
                        context.send(viewAction: .verifyInviteCode(inviteCode: context.inviteCode))
                    }
                } label: {
                    CompoundIcon(\.sendSolid)
                        .padding(6)
                        .foregroundColor(context.viewState.sendButtonDisabled ? .compound.iconDisabled : .zero.iconAccentTertiary)
                        .background {
                            Circle()
                                .foregroundColor(context.viewState.sendButtonDisabled ? .clear : Asset.Colors.zeroDarkGrey.swiftUIColor)
                        }
                }
                .disabled(context.viewState.sendButtonDisabled)
                .animation(.linear(duration: 0.1).disabledDuringTests(), value: context.viewState.sendButtonDisabled)
                .keyboardShortcut(.return, modifiers: [.command])
                .padding(.horizontal, 6)
            }
        }
        .padding(.bottom, 32)
    }
}
