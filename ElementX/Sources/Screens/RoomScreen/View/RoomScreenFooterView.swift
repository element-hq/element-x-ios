//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct RoomScreenFooterView: View {
    let details: RoomScreenFooterViewDetails?
    let mediaProvider: MediaProviderProtocol?
    let callback: (RoomScreenFooterViewAction) -> Void
    
    var body: some View {
        if let details {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    Color.compound.borderInfoSubtle
                        .frame(height: 1)
                    LinearGradient(colors: [.compound.bgInfoSubtle, .compound.bgCanvasDefault],
                                   startPoint: .top,
                                   endPoint: .bottom)
                }
                
                switch details {
                case .pinViolation(let member, let learnMoreURL):
                    pinViolation(member: member, learnMoreURL: learnMoreURL)
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
                
                Text(pinViolationDescriptionWithLearnMoreLink(displayName: member.disambiguatedDisplayName ?? member.userID,
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
    
    private func pinViolationDescriptionWithLearnMoreLink(displayName: String, url: URL) -> AttributedString {
        let linkPlaceholder = "{link}"
        var description = AttributedString(L10n.cryptoIdentityChangePinViolation(displayName, linkPlaceholder))
        var linkString = AttributedString(L10n.actionLearnMore)
        linkString.link = url
        linkString.bold()
        description.replace(linkPlaceholder, with: linkString)
        return description
    }
}

struct RoomScreenFooterView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        RoomScreenFooterView(details: .pinViolation(member: RoomMemberProxyMock.mockBob, learnMoreURL: "https://element.io/"),
                             mediaProvider: MediaProviderMock(configuration: .init())) { _ in }
    }
}
