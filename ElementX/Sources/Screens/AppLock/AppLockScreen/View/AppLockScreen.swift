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

import Compound
import SwiftUI

struct AppLockScreen: View {
    @ObservedObject var context: AppLockScreenViewModel.Context
    
    /// The size of each dot within the PIN input field.
    @ScaledMetric private var pinDotSize = 14
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
        .environment(\.backgroundStyle, AnyShapeStyle(Color.compound.bgCanvasDefault))
        .disabled(context.viewState.forcedLogoutIndicator != nil)
        .overlay {
            context.viewState.forcedLogoutIndicator.map(UserIndicatorModalView.init)
                .animation(.elementDefault, value: context.viewState.forcedLogoutIndicator)
        }
        .alert(item: $context.alertInfo)
    }
    
    var header: some View {
        VStack(spacing: 8) {
            CompoundIcon(\.lock, size: .medium, relativeTo: .compound.headingMDBold)
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
            Circle()
                .fill(context.viewState.numberOfDigitsEntered > 0 ? .compound.iconPrimary : .compound.bgSubtlePrimary)
                .frame(width: pinDotSize, height: pinDotSize)
            Circle()
                .fill(context.viewState.numberOfDigitsEntered > 1 ? .compound.iconPrimary : .compound.bgSubtlePrimary)
                .frame(width: pinDotSize, height: pinDotSize)
            Circle()
                .fill(context.viewState.numberOfDigitsEntered > 2 ? .compound.iconPrimary : .compound.bgSubtlePrimary)
                .frame(width: pinDotSize, height: pinDotSize)
            Circle()
                .fill(context.viewState.numberOfDigitsEntered > 3 ? .compound.iconPrimary : .compound.bgSubtlePrimary)
                .frame(width: pinDotSize, height: pinDotSize)
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
