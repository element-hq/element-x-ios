//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct PhoneEntryScreen: View {
    @Bindable var context: PhoneEntryScreenViewModel.Context
    @FocusState private var isPhoneFieldFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                header
                inputCard
                actions
                trustPills
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
            .readableFrame()
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $context.isCountryPickerPresented) {
            CountryPickerScreen(selectedCountry: context.viewState.selectedCountry) { country in
                context.send(viewAction: .countrySelected(country))
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 20) {
            // App-icon logo: a one-shot fly-in/spin entrance, raised wolf+bubble relief, device-motion
            // parallax, and a contained Gua-green aura (see GuaWelcomeLogo).
            GuaWelcomeLogo(animated: !reduceMotion)

            VStack(spacing: 8) {
                Text(L10n.screenPhoneLoginWelcome)
                    .font(.compound.headingLGBold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                Text(L10n.screenPhoneLoginTitle)
                    .font(.compound.bodyLG)
                    .foregroundStyle(.compound.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 24)
    }

    // MARK: - Input

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                countryButton
                phoneField
            }

            if let errorMessage = context.viewState.errorMessage {
                Text(errorMessage)
                    .font(.compound.bodySM)
                    .foregroundStyle(.compound.textCriticalPrimary)
                    .padding(.horizontal, 4)
            } else {
                Text(L10n.screenPhoneLoginFooter)
                    .font(.compound.bodySM)
                    .foregroundStyle(.compound.textSecondary)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var countryButton: some View {
        Button {
            isPhoneFieldFocused = false
            context.isCountryPickerPresented = true
        } label: {
            HStack(spacing: 6) {
                Text(context.viewState.selectedCountry.flag)
                    .font(.title3)
                Text("+\(context.viewState.selectedCountry.dialCode)")
                    .font(.compound.bodyLG)
                    .foregroundStyle(.compound.textPrimary)
                CompoundIcon(\.chevronDown, size: .small, relativeTo: .compound.bodyLG)
                    .foregroundStyle(.compound.iconSecondary)
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(.compound.bgSubtleSecondary, in: RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityLabel("Country code: \(context.viewState.selectedCountry.name) plus \(context.viewState.selectedCountry.dialCode)")
        .accessibilityHint("Opens country picker")
    }

    private var phoneField: some View {
        TextField(context.viewState.selectedCountry.nationalExample, text: $context.localPhoneNumber)
            .keyboardType(.phonePad)
            .textContentType(.telephoneNumber)
            .font(.compound.bodyLG)
            .foregroundStyle(.compound.textPrimary)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(.compound.bgSubtleSecondary, in: RoundedRectangle(cornerRadius: 14))
            .focused($isPhoneFieldFocused)
            .submitLabel(.done)
            .onSubmit {
                if context.viewState.canContinue {
                    context.send(viewAction: .continueTapped)
                }
            }
            .onChange(of: context.localPhoneNumber) { _, _ in
                context.send(viewAction: .phoneNumberChanged)
            }
            .onAppear { isPhoneFieldFocused = true }
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 16) {
            Button {
                isPhoneFieldFocused = false
                context.send(viewAction: .continueTapped)
            } label: {
                Label(context.viewState.isSubmitting ? L10n.commonLoading : L10n.actionContinue,
                      icon: \.arrowRight)
            }
            .buttonStyle(.compound(.primary))
            .disabled(!context.viewState.canContinue)

            if context.viewState.isLegacyAuthEnabled {
                Button {
                    context.send(viewAction: .useLegacyAuthTapped)
                } label: {
                    Label(L10n.screenPhoneLoginLegacy, icon: \.lock)
                }
                .buttonStyle(.compound(.tertiary))
            }
        }
    }

    // MARK: - Trust

    /// On-brand trust signal reassuring the user before they hand over a number.
    private var trustPills: some View {
        TrustPill(systemImage: "lock.fill", title: L10n.screenOnboardingTrustEncrypted)
            .padding(.top, 8)
    }
}

/// A single capsule "trust" chip — icon + short claim, sitting quietly on the canvas.
private struct TrustPill: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.iconSuccessPrimary)
            Text(title)
                .font(.compound.bodyMDSemibold)
                .foregroundColor(.compound.textPrimary)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 16)
        .background(.compound.bgSubtleSecondary, in: Capsule())
    }
}

// MARK: - Previews

struct PhoneEntryScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = PhoneEntryScreenViewModel(isLegacyAuthEnabled: false)
    static let viewModelLegacy = PhoneEntryScreenViewModel(isLegacyAuthEnabled: true)

    static var previews: some View {
        NavigationStack {
            PhoneEntryScreen(context: viewModel.context)
        }
        .previewDisplayName("Default")

        NavigationStack {
            PhoneEntryScreen(context: viewModelLegacy.context)
        }
        .previewDisplayName("Legacy enabled")

        NavigationStack {
            PhoneEntryScreen(context: viewModel.context)
        }
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark")
    }
}
