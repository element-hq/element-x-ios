//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

/// The screen shown at the beginning of the onboarding flow.
struct CompleteProfileScreen: View {
    @ObservedObject var context: CompleteProfileScreenViewModel.Context
    
    @FocusState private var isDisplayNameFocused: Bool
    
    var body: some View {
        VStack {
            Text("Complete Profile")
                .font(.compound.bodyMDSemibold)
            
            VStack {
                avatar
                
                nameSection
                
                submitButton
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 64)
            
            Spacer()
        }
        .confirmationDialog("", isPresented: $context.showMediaSheet) {
            mediaActionSheet
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var avatar: some View {
        Button {
            context.send(viewAction: .presentMediaSource)
        } label: {
            OverridableAvatarImage(overrideURL: context.viewState.localMedia?.thumbnailURL,
                                   url: context.viewState.selectedAvatarURL,
                                   name: nil,
                                   contentID: nil,
                                   avatarSize: .user(on: .editUserDetails),
                                   mediaProvider: context.mediaProvider,
                                   onTap: { context.send(viewAction: .presentMediaSource) })
                .overlay(alignment: .bottomTrailing) {
                    avatarOverlayIcon
                }
        }
    }
    
    private var nameSection: some View {
        VStack {
            TextField(text: $context.name) {
                Text("DisplayName").foregroundColor(.compound.textSecondary)
            }
            .focused($isDisplayNameFocused)
            .textFieldStyle(.element(accessibilityIdentifier: "complete-profile_display_name"))
            .disableAutocorrection(true)
            .autocapitalization(.none)
            .submitLabel(.done)
            .onSubmit(submit)
            
            if !context.name.isEmpty, !context.viewState.hasValidInput {
                InfoBox(text: "Name must be atleast 3 characters or more upto 24 characters", type: .error)
            }
        }
        .frame(maxWidth: .infinity)
        .listRowBackground(Color.clear)
        .padding(.top, 32)
    }
    
    private var submitButton: some View {
        Button {
            submit()
        } label: {
            Text("Continue")
        }
        .buttonStyle(.compound(.primary))
        .disabled(!context.viewState.canSubmit)
        .padding(.vertical, 24)
    }
    
    private var avatarOverlayIcon: some View {
        CompoundIcon(\.editSolid, size: .xSmall, relativeTo: .compound.bodyLG)
            .foregroundColor(.white)
            .padding(4)
            .background {
                Circle()
                    .foregroundColor(.black)
            }
    }
    
    @ViewBuilder
    private var mediaActionSheet: some View {
        Button {
            context.send(viewAction: .displayCameraPicker)
        } label: {
            Text(L10n.actionTakePhoto)
        }
        Button {
            context.send(viewAction: .displayMediaPicker)
        } label: {
            Text(L10n.actionChoosePhoto)
        }
    }
    
    private func submit() {
        guard context.viewState.canSubmit else { return }
        context.send(viewAction: .completeProfile)
        isDisplayNameFocused = false
    }
}
