//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct RoomScreenFooterView: View {
    let details: RoomScreenFooterViewDetails?
    let mediaProvider: MediaProviderProtocol?
    let callback: (RoomScreenFooterViewAction) -> Void
    
    var body: some View {
        if let details {
            ZStack(alignment: .top) {
                switch details {
                case .pinViolation(let member, let learnMoreURL):
                    VStack(spacing: 0) {
                        Color.compound.borderInfoSubtle
                            .frame(height: 1)
                        LinearGradient(colors: [.compound.bgInfoSubtle, .compound.bgCanvasDefault],
                                       startPoint: .top,
                                       endPoint: .bottom)
                    }
                    pinViolation(member: member, learnMoreURL: learnMoreURL)
                case .verificationViolation(member: let member, learnMoreURL: let learnMoreURL):
                    VStack(spacing: 0) {
                        Color.compound.borderCriticalSubtle
                            .frame(height: 1)
                        LinearGradient(colors: [.compound.bgCriticalSubtle, .compound.bgCanvasDefault],
                                       startPoint: .top,
                                       endPoint: .bottom)
                    }
                    verificationViolation(member: member, learnMoreURL: learnMoreURL)
                }
            }
            .padding(.top, 8)
            .fixedSize(horizontal: false, vertical: true)
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
            
            Button(L10n.actionOk) {
                callback(.resolvePinViolation(userID: member.userID))
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
            
            Button(L10n.cryptoIdentityChangeWithdrawVerificationAction) {
                callback(.resolveVerificationViolation(userID: member.userID))
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
