//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct AppLockScreen: View {
    @ObservedObject var context: AppLockScreenViewModel.Context
    
    /// Used to animate the PIN input field on failure.
    @State private var pinInputFieldOffset = 0.0
    
    /// A focus state to highlight a failed PIN entry in VoiceOver.
    @AccessibilityFocusState private var accessibilitySubtitleFocus: Bool
    
    var subtitleColor: Color {
        context.viewState.isSubtitleWarning ? .compound.textCriticalPrimary : .compound.textPrimary
    }
    
    var body: some View {
        FullscreenDialog {
            VStack(spacing: 32) {
                header
                
                pinInputField
                    .padding(.bottom, 16)
                    .offset(x: pinInputFieldOffset)
                    .onChange(of: context.viewState.numberOfPINAttempts) { newValue in
                        guard newValue > 0 else { return } // Reset without animation in Previews.
                        accessibilitySubtitleFocus = true
                        Task { await animatePINFailure() }
                    }
                    .accessibilityLabel(L10n.a11yPinField)
                    .accessibilityValue(L10n.a11yDigitsEntered(context.viewState.numberOfDigitsEntered))
                
                AppLockScreenPINKeypad(pinCode: $context.pinCode)
            }
        } bottomContent: {
            Button(L10n.screenAppLockForgotPin) {
                context.send(viewAction: .forgotPIN)
            }
            .font(.compound.bodyMDSemibold)
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .disabled(context.viewState.forcedLogoutIndicator != nil)
        .overlay {
            context.viewState.forcedLogoutIndicator.map(UserIndicatorModalView.init)
                .animation(.elementDefault, value: context.viewState.forcedLogoutIndicator)
        }
        .alert(item: $context.alertInfo)
    }
    
    var header: some View {
        VStack(spacing: 8) {
            CompoundIcon(\.lockSolid, size: .medium, relativeTo: .compound.headingMDBold)
                .padding(.bottom, 8)
                .accessibilityHidden(true)
            
            Text(L10n.commonEnterYourPin)
                .font(.compound.headingMDBold)
                .foregroundColor(.compound.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(context.viewState.subtitle)
                .font(.compound.bodyMD)
                .foregroundColor(subtitleColor)
                .multilineTextAlignment(.center)
                .accessibilityFocused($accessibilitySubtitleFocus)
        }
    }
    
    /// The row of dots showing how many digits have been entered.
    var pinInputField: some View {
        HStack(spacing: 24) {
            /// The size of each dot within the PIN input field.
            let pinDotSize: CGFloat = 14
            Circle()
                .fill(context.viewState.numberOfDigitsEntered > 0 ? .compound.iconPrimary : .compound.bgSubtlePrimary)
                .scaledFrame(size: pinDotSize)
            Circle()
                .fill(context.viewState.numberOfDigitsEntered > 1 ? .compound.iconPrimary : .compound.bgSubtlePrimary)
                .scaledFrame(size: pinDotSize)
            Circle()
                .fill(context.viewState.numberOfDigitsEntered > 2 ? .compound.iconPrimary : .compound.bgSubtlePrimary)
                .scaledFrame(size: pinDotSize)
            Circle()
                .fill(context.viewState.numberOfDigitsEntered > 3 ? .compound.iconPrimary : .compound.bgSubtlePrimary)
                .scaledFrame(size: pinDotSize)
        }
    }
    
    func animatePINFailure() async {
        withAnimation(.spring(response: 0, dampingFraction: 0.7, blendDuration: 0.0)) {
            pinInputFieldOffset = 15
        }
        
        try? await Task.sleep(for: .milliseconds(50))
        withAnimation(.spring(response: 0.1, dampingFraction: 0.3, blendDuration: 0.1)) {
            pinInputFieldOffset = 0
        }
        
        try? await Task.sleep(for: .milliseconds(100))
        context.send(viewAction: .clearPINCode)
    }
}

// MARK: - Previews

struct AppLockScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = AppLockScreenViewModel(appLockService: AppLockServiceMock.mock())
    
    static var previews: some View {
        NavigationStack {
            AppLockScreen(context: viewModel.context)
        }
    }
}
