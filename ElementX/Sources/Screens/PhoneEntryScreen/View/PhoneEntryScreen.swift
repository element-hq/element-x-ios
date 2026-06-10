//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct PhoneEntryScreen: View {
    @Bindable var context: PhoneEntryScreenViewModel.Context
    @FocusState private var isPhoneFieldFocused: Bool

    var body: some View {
        Form {
            Section {
                HStack(spacing: 8) {
                    countryButton
                    phoneField
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } header: {
                Text(L10n.screenPhoneLoginTitle)
            } footer: {
                if let errorMessage = context.viewState.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.compound.textCriticalPrimary)
                } else {
                    Text(L10n.screenPhoneLoginFooter)
                }
            }

            Section {
                ListRow(label: .centeredAction(title: context.viewState.isSubmitting ? L10n.commonLoading : L10n.actionContinue,
                                               icon: \.arrowRight),
                        kind: .button {
                            isPhoneFieldFocused = false
                            context.send(viewAction: .continueTapped)
                        })
                        .disabled(!context.viewState.canContinue)
            }

            if context.viewState.isLegacyAuthEnabled {
                Section {
                    ListRow(label: .centeredAction(title: L10n.screenPhoneLoginLegacy,
                                                   icon: \.lock),
                            kind: .button {
                                context.send(viewAction: .useLegacyAuthTapped)
                            })
                }
            }
        }
        .compoundList()
        .navigationTitle(L10n.screenPhoneLoginWelcome)
        .sheet(isPresented: $context.isCountryPickerPresented) {
            CountryPickerScreen(selectedCountry: context.viewState.selectedCountry) { country in
                context.send(viewAction: .countrySelected(country))
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
            .frame(height: 48)
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
            .frame(maxWidth: .infinity, minHeight: 48)
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
    }
}
