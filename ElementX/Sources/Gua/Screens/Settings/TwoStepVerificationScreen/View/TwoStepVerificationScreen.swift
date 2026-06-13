//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct TwoStepVerificationScreen: View {
    @Bindable var context: TwoStepVerificationScreenViewModel.Context
    @FocusState private var isPhoneFieldFocused: Bool

    var body: some View {
        Form {
            switch context.viewState.phase {
            case .loading:
                loadingSection
            case .overviewNoPin:
                overviewSection(hasPin: false)
            case .overviewHasPin:
                overviewSection(hasPin: true)
            case .enteringPhone:
                phoneEntrySection
            case .enteringCurrent, .enteringOtp, .enteringNew, .confirmingNew, .submitting:
                pinEntrySection
            }
        }
        .compoundList()
        .navigationTitle(context.viewState.titleKey)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isEnteringFlow {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.actionCancel) { context.send(viewAction: .cancelEntry) }
                }
            }
        }
        .sheet(isPresented: $context.isCountryPickerPresented) {
            CountryPickerScreen(selectedCountry: context.viewState.selectedCountry) { country in
                context.send(viewAction: .countrySelected(country))
            }
        }
    }

    private var isEnteringFlow: Bool {
        switch context.viewState.phase {
        case .enteringPhone, .enteringCurrent, .enteringOtp, .enteringNew, .confirmingNew, .submitting:
            return true
        default:
            return false
        }
    }

    private var loadingSection: some View {
        Section {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, 24)
        }
    }

    @ViewBuilder
    private func overviewSection(hasPin: Bool) -> some View {
        Section {
            ListRow(label: .default(title: hasPin ? L10n.screenTwoStepVerificationStatusOn : L10n.screenTwoStepVerificationStatusOff,
                                    icon: \.lock),
                    kind: .label)
        } header: {
            Text(L10n.screenTwoStepVerificationOverviewHeader)
        } footer: {
            Text(hasPin ? L10n.screenTwoStepVerificationOverviewFooterOn : L10n.screenTwoStepVerificationOverviewFooterOff)
        }

        Section {
            if hasPin {
                ListRow(label: .centeredAction(title: L10n.screenTwoStepVerificationChangeButton,
                                               icon: \.edit),
                        kind: .button { context.send(viewAction: .startChange) })
            } else {
                ListRow(label: .centeredAction(title: L10n.screenTwoStepVerificationSetButton,
                                               icon: \.lock),
                        kind: .button { context.send(viewAction: .startSetup) })
            }
        }
    }

    @ViewBuilder
    private var phoneEntrySection: some View {
        Section {
            HStack(spacing: 8) {
                countryButton
                phoneField
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } header: {
            Text(context.viewState.titleKey)
        } footer: {
            if let errorMessage = context.viewState.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.compound.textCriticalPrimary)
            } else {
                Text(context.viewState.footerKey)
            }
        }

        Section {
            ListRow(label: .centeredAction(title: L10n.actionContinue, icon: \.arrowRight),
                    kind: .button {
                        isPhoneFieldFocused = false
                        context.send(viewAction: .continueTapped)
                    })
                    .disabled(!context.viewState.canContinue)
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
                    isPhoneFieldFocused = false
                    context.send(viewAction: .continueTapped)
                }
            }
            .onChange(of: context.localPhoneNumber) { _, _ in
                context.send(viewAction: .phoneChanged)
            }
            .onAppear { isPhoneFieldFocused = true }
    }

    @ViewBuilder
    private var pinEntrySection: some View {
        Section {
            PinBubbleField(pin: $context.pin,
                           length: codeFieldLength,
                           hasError: context.viewState.errorMessage != nil)
                .onChange(of: context.pin) {
                    context.send(viewAction: .pinChanged)
                }
                .id(context.viewState.phase)
        } header: {
            Text(context.viewState.titleKey)
        } footer: {
            if let errorMessage = context.viewState.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.compound.textCriticalPrimary)
            } else {
                Text(context.viewState.footerKey)
            }
        }

        Section {
            ListRow(label: .centeredAction(title: context.viewState.phase == .submitting ? L10n.commonLoading : L10n.actionContinue,
                                           icon: \.arrowRight),
                    kind: .button { context.send(viewAction: .continueTapped) })
                .disabled(!context.viewState.canContinue)
        }
    }

    private var codeFieldLength: Int {
        context.viewState.phase == .enteringOtp
            ? TwoStepVerificationScreenViewState.otpLength
            : TwoStepVerificationScreenViewState.pinLength
    }
}

// MARK: - Previews

struct TwoStepVerificationScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel: TwoStepVerificationScreenViewModel = {
        let clientProxy = ClientProxyMock(.init())
        let userIndicatorController = UserIndicatorControllerMock()
        let identityServiceClient = IdentityServiceClient(baseURL: URL(string: "https://example.com")!)
        return TwoStepVerificationScreenViewModel(clientProxy: clientProxy,
                                                  identityServiceClient: identityServiceClient,
                                                  userIndicatorController: userIndicatorController)
    }()

    static var previews: some View {
        NavigationStack {
            TwoStepVerificationScreen(context: viewModel.context)
        }
    }
}
