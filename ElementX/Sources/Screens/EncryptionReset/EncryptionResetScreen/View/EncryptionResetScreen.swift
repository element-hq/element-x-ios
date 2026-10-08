//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct EncryptionResetScreen: View {
    @Bindable var context: EncryptionResetScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog {
            mainContent
        } bottomContent: {
            actionButtons
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .interactiveDismissDisabled()
        .toolbar { toolbar }
        .toolbar(.visible, for: .navigationBar)
        .alert(item: $context.alertInfo)
    }
    
    private var variant: EncryptionResetScreenVariant {
        context.viewState.variant
    }
    
    /// The main content of the screen that is shown inside the scroll view.
    private var mainContent: some View {
        VStack(spacing: 24) {
            header
            
            switch variant {
            case .hasConfirmationOptions:
                checkmarkList(showsDevicesItem: true)
                footer
            case .noOptionsWithEncryptedChats:
                checkmarkList(showsDevicesItem: false)
            case .noOptionsWithoutEncryptedChats:
                noChatsMessage
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            BigIcon(icon: \.userProfile)
                .padding(.bottom, 8)
            
            Text(variant.isResetTheOnlyOption ? UntranslatedL10n.screenEncryptionResetNoOptionsTitle : L10n.screenEncryptionResetTitle)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
            
            Text(variant.isResetTheOnlyOption ? UntranslatedL10n.screenEncryptionResetNoOptionsSubtitle : UntranslatedL10n.screenEncryptionResetSubtitle)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
        }
    }
    
    private var footer: some View {
        Text(L10n.screenEncryptionResetFooter)
            .font(.compound.bodyMD)
            .foregroundColor(.compound.textCriticalPrimary)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.compound.bgCriticalSubtle, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var noChatsMessage: some View {
        VisualListItem(title: UntranslatedL10n.screenEncryptionResetNoChatsMessage, position: .single) {
            CompoundIcon(\.check)
                .foregroundColor(.compound.iconAccentPrimary)
                .alignmentGuide(.top) { _ in 2 }
        }
        .environment(\.backgroundStyle, AnyShapeStyle(.compound.bgSubtleSecondary))
    }
    
    private func checkmarkList(showsDevicesItem: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            checkMarkItem(title: L10n.screenEncryptionResetBullet1, icon: \.checkCircle, position: .top, positive: true)
            checkMarkItem(title: L10n.screenEncryptionResetBullet2, icon: \.visibilityOff, position: .middle, positive: false)
            checkMarkItem(title: L10n.screenEncryptionResetBullet3, icon: \.user, position: showsDevicesItem ? .middle : .bottom, positive: false)
            if showsDevicesItem {
                checkMarkItem(title: UntranslatedL10n.screenEncryptionResetBullet4, icon: \.devices, position: .bottom, positive: false)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .environment(\.backgroundStyle, AnyShapeStyle(.compound.bgSubtleSecondary))
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button(L10n.screenEncryptionResetActionContinueReset, role: variant.isResetTheOnlyOption ? nil : .destructive) {
                context.send(viewAction: .reset)
            }
            .buttonStyle(.compound(.primary))
            .accessibilityIdentifier(A11yIdentifiers.encryptionResetScreen.continueReset)
            
            if variant.isResetTheOnlyOption {
                Button(UntranslatedL10n.screenIdentityConfirmationSignOut) {
                    context.send(viewAction: .signOut)
                }
                .buttonStyle(.compound(.tertiary))
            }
        }
    }
    
    private func checkMarkItem(title: String, icon: KeyPath<CompoundIcons, Image>, position: ListPosition, positive: Bool) -> some View {
        VisualListItem(title: title, position: position) {
            CompoundIcon(icon)
                .foregroundColor(positive ? .compound.iconAccentPrimary : .compound.iconSecondary)
                .alignmentGuide(.top) { _ in 2 }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if !variant.isResetTheOnlyOption {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
            }
        }
    }
}

// MARK: - Previews

struct EncryptionResetScreen_Previews: PreviewProvider, TestablePreview {
    static let hasOptionsViewModel = makeViewModel(variant: .hasConfirmationOptions)
    static let encryptedChatsViewModel = makeViewModel(variant: .noOptionsWithEncryptedChats)
    static let noChatsViewModel = makeViewModel(variant: .noOptionsWithoutEncryptedChats)
    
    static var previews: some View {
        ElementNavigationStack {
            EncryptionResetScreen(context: hasOptionsViewModel.context)
        }
        .previewDisplayName("Has confirmation options")
        
        ElementNavigationStack {
            EncryptionResetScreen(context: encryptedChatsViewModel.context)
        }
        .previewDisplayName("No options, encrypted chats")
        
        ElementNavigationStack {
            EncryptionResetScreen(context: noChatsViewModel.context)
        }
        .previewDisplayName("No options, no chats")
    }
    
    static func makeViewModel(variant: EncryptionResetScreenVariant) -> EncryptionResetScreenViewModel {
        EncryptionResetScreenViewModel(clientProxy: ClientProxyMock(.init()),
                                       variant: variant,
                                       userIndicatorController: UserIndicatorControllerMock())
    }
}
