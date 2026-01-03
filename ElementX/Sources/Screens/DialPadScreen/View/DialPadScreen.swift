//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct DialPadScreen: View {
    @ObservedObject var context: DialPadScreenViewModel.Context
    
    var body: some View {
        VStack(spacing: 32) {
            // Display Area
            Text(context.viewState.bindings.phoneNumber)
                .font(.compound.headingXL)
                .foregroundColor(.compound.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 60)
                .padding()
            
            // Keypad
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                ForEach(1...9, id: \.self) { digit in
                    DialPadButton(title: "\(digit)", action: {
                        context.send(viewAction: .digit("\(digit)"))
                    })
                }
                
                DialPadButton(title: "*", action: {
                    context.send(viewAction: .digit("*"))
                })
                
                DialPadButton(title: "0", action: {
                    context.send(viewAction: .digit("0"))
                })
                
                DialPadButton(title: "#", action: {
                    context.send(viewAction: .digit("#"))
                })
            }
            .padding(.horizontal)
            
            HStack(spacing: 40) {
                // Spacer to center the dial button relative to the grid if needed, or backspace on the right
                Spacer()
                    .frame(width: 60, height: 60)
                
                // Dial Button
                Button {
                    context.send(viewAction: .dial)
                } label: {
                    Image(systemName: "phone.fill")
                        .font(.title)
                        .scaleEffect(1.5)
                        .foregroundColor(.white)
                        .frame(width: 72, height: 72)
                        .background(Color.compound.iconAccentTertiary)
                        .clipShape(Circle())
                }
                .disabled(context.viewState.bindings.phoneNumber.isEmpty)
                
                // Backspace Button
                Button {
                    context.send(viewAction: .delete)
                } label: {
                    Image(systemName: "delete.left.fill")
                        .font(.title)
                        .foregroundColor(.compound.iconSecondary)
                        .frame(width: 60, height: 60)
                }
                .opacity(context.viewState.bindings.phoneNumber.isEmpty ? 0 : 1)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
        .track(screen: .StartChat) // Tracking as part of start chat flows for now
        .navigationTitle("Dial Pad")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .close)
                }
            }
        }
        .alert(item: $context.alertInfo)
    }
}

struct DialPadButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.compound.headingLG)
                .foregroundColor(.compound.textPrimary)
                .frame(width: 80, height: 80)
                .background(Color.compound.bgSubtleSecondary)
                .clipShape(Circle())
        }
    }
}

struct DialPadScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = {
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "@userid:example.com"))))
        return DialPadScreenViewModel(userSession: userSession,
                                      analytics: ServiceLocator.shared.analytics,
                                      userIndicatorController: UserIndicatorControllerMock())
    }()
    
    static var previews: some View {
        NavigationStack {
            DialPadScreen(context: viewModel.context)
        }
    }
}
