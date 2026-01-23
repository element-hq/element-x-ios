//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomScreenFooterView: View {
    let details: RoomScreenFooterViewDetails?
    let mediaProvider: MediaProviderProtocol?
    let callback: (RoomScreenFooterViewAction) -> Void
    
    private var borderColor: Color {
        switch details {
        case .pinViolation:
            .compound.borderInfoSubtle
        case .verificationViolation:
            .compound.borderCriticalSubtle
        case .none:
            Color.compound.bgCanvasDefault
        }
    }
    
    private var gradient: Gradient {
        switch details {
        case .pinViolation:
            .compound.info
        case .verificationViolation:
            Gradient(colors: [.compound.bgCriticalSubtle, .clear])
        case .none:
            Gradient(colors: [.clear])
        }
    }
    
    var body: some View {
        if let details {
            detailsView(details)
                .highlight(gradient: gradient,
                           borderColor: borderColor,
                           backgroundColor: .compound.bgCanvasDefault)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    @ViewBuilder
    private func detailsView(_ details: RoomScreenFooterViewDetails) -> some View {
        switch details {
        case .pinViolation(let member, let learnMoreURL):
            pinViolation(member: member, learnMoreURL: learnMoreURL)
        case .verificationViolation(member: let member, learnMoreURL: let learnMoreURL):
            verificationViolation(member: member, learnMoreURL: learnMoreURL)
        }
    }
    
    private func pinViolation(member: RoomMemberProxyProtocol,
                              learnMoreURL: URL) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                LoadableAvatarImage(url: member.avatarURL,
                                    name: member.disambiguatedDisplayName,
                                    contentID: member.userID,
                                    avatarSize: .user(on: .timeline),
                                    mediaProvider: mediaProvider)
                
                Text(pinViolationDescriptionWithLearnMoreLink(displayName: member.displayName,
                                                              userID: member.userID,
                                                              url: learnMoreURL))
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textPrimary)
            }
            
            Button {
                callback(.resolvePinViolation(userID: member.userID))
            } label: {
                Text(L10n.actionDismiss)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.compound(.primary, size: .medium))
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private func verificationViolation(member: RoomMemberProxyProtocol,
                                       learnMoreURL: URL) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                LoadableAvatarImage(url: member.avatarURL,
                                    name: member.disambiguatedDisplayName,
                                    contentID: member.userID,
                                    avatarSize: .user(on: .timeline),
                                    mediaProvider: mediaProvider)
                
                Text(verificationViolationDescriptionWithLearnMoreLink(displayName: member.displayName,
                                                                       userID: member.userID,
                                                                       url: learnMoreURL))
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textCriticalPrimary)
            }
            
            Button {
                callback(.resolveVerificationViolation(userID: member.userID))
            } label: {
                Text(L10n.cryptoIdentityChangeWithdrawVerificationAction)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.compound(.primary, size: .medium))
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private func pinViolationDescriptionWithLearnMoreLink(displayName: String?, userID: String, url: URL) -> AttributedString {
        let userIDPlaceholder = "{mxid}"
        let linkPlaceholder = "{link}"
        let displayName = displayName ?? fallbackDisplayName(userID)
        var description = AttributedString(L10n.cryptoIdentityChangePinViolationNew(displayName, userIDPlaceholder, linkPlaceholder))
        
        var userIDString = AttributedString(L10n.cryptoIdentityChangePinViolationNewUserId(userID))
        userIDString.bold()
        description.replace(userIDPlaceholder, with: userIDString)
        
        var linkString = AttributedString(L10n.actionLearnMore)
        linkString.link = url
        linkString.bold()
        description.replace(linkPlaceholder, with: linkString)
        return description
    }
    
    private func verificationViolationDescriptionWithLearnMoreLink(displayName: String?, userID: String, url: URL) -> AttributedString {
        let userIDPlaceholder = "{mxid}"
        let linkPlaceholder = "{link}"
        let displayName = displayName ?? fallbackDisplayName(userID)
        var description = AttributedString(L10n.cryptoIdentityChangeVerificationViolationNew(displayName, userIDPlaceholder, linkPlaceholder))
        
        var userIDString = AttributedString(L10n.cryptoIdentityChangePinViolationNewUserId(userID))
        userIDString.bold()
        description.replace(userIDPlaceholder, with: userIDString)
        
        var linkString = AttributedString(L10n.actionLearnMore)
        linkString.link = url
        linkString.bold()
        description.replace(linkPlaceholder, with: linkString)
        return description
    }
    
    private func fallbackDisplayName(_ userID: String) -> String {
        guard let localpart = userID.components(separatedBy: ":").first else { return userID }
        return String(localpart.trimmingPrefix("@"))
    }
}

struct RoomScreenFooterView_Previews: PreviewProvider, TestablePreview {
    static let bobDetails: RoomScreenFooterViewDetails = .pinViolation(member: RoomMemberProxyMock.mockBob,
                                                                       learnMoreURL: "https://element.io/")
    static let noNameDetails: RoomScreenFooterViewDetails = .pinViolation(member: RoomMemberProxyMock.mockNoName,
                                                                          learnMoreURL: "https://element.io/")
    
    static let verificationViolationDetails: RoomScreenFooterViewDetails = .verificationViolation(member: RoomMemberProxyMock.mockBob,
                                                                                                  learnMoreURL: "https://element.io/")
    
    static var previews: some View {
        RoomScreenFooterView(details: bobDetails, mediaProvider: MediaProviderMock(configuration: .init())) { _ in }
            .previewDisplayName("With displayname")
        RoomScreenFooterView(details: noNameDetails, mediaProvider: MediaProviderMock(configuration: .init())) { _ in }
            .previewDisplayName("Without displayname")
        RoomScreenFooterView(details: verificationViolationDetails, mediaProvider: MediaProviderMock(configuration: .init())) { _ in }
            .previewDisplayName("Verification Violation")
    }
}
