//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI
import SwiftUIIntrospect

struct RoomHeaderView: View {
    struct DMRecipientDetails {
        var statusEmoji: Character?
        var verification: UserIdentityVerificationState?
    }
    
    let roomName: String
    var roomSubtitle: String?
    let roomAvatar: RoomAvatar
    var dmRecipientDetails = DMRecipientDetails()
    var roomHistorySharingState: RoomHistorySharingState?
    
    let mediaProvider: MediaProviderProtocol?
    
    let action: () -> Void
    
    var body: some View {
        if #available(iOS 26.0, *) {
            // On iOS 26+ we use the toolbarRole(.editor) to leading align.
            content
                // Not using a Button here so that we get our custom padding around the avatar. This also
                // helps fix a bug where the top pixel was being clipped during the push/pop animation as
                // the Button styling results in a view that is slightly taller than a bar item should be.
                .padding(6)
                .padding(.trailing, 6)
                .glassEffect(.regular.interactive())
                .roomHeaderAction(action)
        } else {
            // On iOS 18 and lower, the editor role causes an animation glitch with the back button whenever
            // you push a screen whilst the large title is visible on the room screen.
            content
                // So take up as much space as possible, with a leading alignment for use in the default principal toolbar position
                .frame(idealWidth: .greatestFiniteMagnitude, maxWidth: .infinity, alignment: .leading)
                .roomHeaderAction(action)
        }
    }
    
    private var content: some View {
        HStack(spacing: 8) {
            avatarImage
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 0) {
                roomDetails
                
                if let roomSubtitle {
                    Text(roomSubtitle)
                        .lineLimit(1)
                        .font(.compound.bodyXS)
                        .foregroundStyle(.compound.textSecondary)
                }
            }
        }
    }
    
    private var roomDetails: some View {
        HStack(spacing: 4) {
            HStack(spacing: 8) {
                Text(roomName)
                    .lineLimit(1)
                    .font(.compound.bodyMDSemibold)
                    .foregroundStyle(.compound.textPrimary)
                    .accessibilityIdentifier(A11yIdentifiers.roomScreen.name)
                
                if let statusEmoji = dmRecipientDetails.statusEmoji {
                    Text(String(statusEmoji))
                        .font(.compound.bodyLG)
                        .foregroundStyle(.compound.textPrimary)
                }
            }
            if let verificationState = dmRecipientDetails.verification {
                VerificationBadge(verificationState: verificationState, size: .xSmall, relativeTo: .compound.bodyMDSemibold)
            }
            
            if let historySharingIcon {
                CompoundIcon(historySharingIcon, size: .xSmall, relativeTo: .compound.bodyMDSemibold)
                    .foregroundStyle(.compound.iconInfoPrimary)
            }
        }
    }
    
    private var avatarImage: some View {
        RoomAvatarImage(avatar: roomAvatar,
                        avatarSize: .room(on: .timeline),
                        mediaProvider: mediaProvider)
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.avatar)
    }
    
    private var historySharingIcon: KeyPath<CompoundIcons, Image>? {
        switch roomHistorySharingState {
        case .none, .hidden: nil
        case .shared: \.history
        case .worldReadable: \.userProfileSolid
        }
    }
}

extension RoomHeaderView {
    static var toolbarRole: ToolbarRole {
        if #available(iOS 26.0, *) {
            .editor
        } else {
            .automatic
        }
    }
}

private extension View {
    func roomHeaderAction(_ action: @escaping () -> Void) -> some View {
        // Using a button stops it from getting truncated in the navigation bar
        contentShape(.rect)
            .onTapGesture(perform: action)
            .accessibilityAddTraits(.isButton)
    }
}

extension View {
    // TODO: Remove this workaround once Apple fixes the bug.
    /// Works around an iOS 26+ bug where cancelling the interactive pop gesture leaves the `RoomHeaderView`
    /// at its full width, covering the trailing toolbar items. Apply it to every screen using the header as its title.
    @ViewBuilder
    func fixesTitleViewOnCancelledPop() -> some View {
        if #available(iOS 26, *) {
            modifier(CancelledPopTitleViewFixModifier())
        } else {
            self
        }
    }
}

@available(iOS 26, *)
private struct CancelledPopTitleViewFixModifier: ViewModifier {
    // Gesture recognizers don't retain their targets, so the view keeps the fix alive.
    @State private var fix = CancelledPopTitleViewFix()
    
    func body(content: Content) -> some View {
        content
            .introspect(.navigationStack, on: .supportedVersions, scope: .ancestor) { [fix] navigationController in
                fix.observe(navigationController)
            }
    }
}

@available(iOS 26, *)
private final class CancelledPopTitleViewFix: NSObject {
    private weak var navigationController: UINavigationController?
    
    isolated deinit {
        stopObserving()
    }
    
    func observe(_ navigationController: UINavigationController) {
        guard navigationController !== self.navigationController else { return }
        
        stopObserving()
        self.navigationController = navigationController
        navigationController.interactivePopGestureRecognizer?.addTarget(self, action: #selector(popGestureChanged))
        navigationController.interactiveContentPopGestureRecognizer?.addTarget(self, action: #selector(popGestureChanged))
    }
    
    @objc private func popGestureChanged(_ gesture: UIGestureRecognizer) {
        guard gesture.state == .began,
              let navigationController,
              let transitionCoordinator = navigationController.transitionCoordinator else {
            return
        }
        
        transitionCoordinator.animate(alongsideTransition: nil) { context in
            guard context.isCancelled else { return }
            // UIKit restores the title view's container but never lays the title view out inside it again.
            navigationController.navigationBar.topItem?.titleView?.superview?.setNeedsLayout()
        }
    }
    
    private func stopObserving() {
        navigationController?.interactivePopGestureRecognizer?.removeTarget(self, action: #selector(popGestureChanged))
        navigationController?.interactiveContentPopGestureRecognizer?.removeTarget(self, action: #selector(popGestureChanged))
    }
}

// MARK: - Previews

struct RoomHeaderView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 16) {
                makeHeader(avatarURL: nil)
                makeHeader(avatarURL: .mockMXCAvatar)
                
                makeHeader(avatarURL: .mockMXCAvatar, historySharingState: .shared)
                makeHeader(avatarURL: .mockMXCAvatar, historySharingState: .worldReadable)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                makeHeader(avatarURL: .mockMXCUserAvatar, verificationState: .verified)
                makeHeader(avatarURL: .mockMXCUserAvatar, verificationState: .verificationViolation)
                
                makeHeader(avatarURL: .mockMXCUserAvatar,
                           userStatus: .mockHoliday,
                           verificationState: .notVerified)
                makeHeader(avatarURL: .mockMXCUserAvatar,
                           userStatus: .mockCall,
                           verificationState: .verificationViolation)
                makeHeader(avatarURL: .mockMXCUserAvatar,
                           roomSubtitle: "Subtitle",
                           userStatus: .mockFocussing,
                           verificationState: .verified)
                
                makeHeader(avatarURL: .mockMXCUserAvatar,
                           roomSubtitle: "Subtitle",
                           verificationState: .verified)
                
                makeHeader(avatarURL: .mockMXCUserAvatar,
                           userStatus: .mockHoliday,
                           verificationState: .verified,
                           historySharingState: .shared)
                makeHeader(avatarURL: .mockMXCUserAvatar,
                           verificationState: .verificationViolation,
                           historySharingState: .worldReadable)
            }
        }
        .previewLayout(.sizeThatFits)
    }
    
    @ViewBuilder
    static func makeHeader(avatarURL: URL?,
                           roomSubtitle: String? = nil,
                           userStatus: UserStatus? = nil,
                           verificationState: UserIdentityVerificationState? = nil,
                           historySharingState: RoomHistorySharingState? = nil) -> some View {
        let roomName = verificationState == nil ? "Some Room Name" : "Some User Name"
        RoomHeaderView(roomName: roomName,
                       roomSubtitle: roomSubtitle,
                       roomAvatar: .room(id: "1",
                                         name: roomName,
                                         avatarURL: avatarURL),
                       dmRecipientDetails: .init(statusEmoji: userStatus?.displayed?.emoji,
                                                 verification: verificationState),
                       roomHistorySharingState: historySharingState,
                       
                       mediaProvider: MediaProviderMock(.init())) { }
    }
}
