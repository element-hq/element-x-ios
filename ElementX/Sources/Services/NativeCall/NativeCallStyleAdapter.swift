//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import ElementCallAll
import SwiftUI

// Colours, icons and avatars for the call, read from this app's Compound rather than the package's
// default tokens.
//
// This is the whole reason the package takes a theme rather than depending on Compound itself.
// `Color.compound` is a single shared instance that Element Pro re-brands at runtime from remote
// settings, so a second copy linked inside the package would never see the override and a branded
// deployment would get a stock-coloured call screen. Every member below is a computed property, so
// each read goes to the live instance.

struct NativeCallCompoundTheme: ElementCallTheme {
    var bgCanvasDefault: Color {
        .compound.bgCanvasDefault
    }
    
    var bgCanvasDefaultLevel: Color {
        .compound.bgCanvasDefaultLevel1
    }
    
    var bgSubtleSecondary: Color {
        .compound.bgSubtleSecondary
    }
    
    var bgAccentRest: Color {
        .compound.bgAccentRest
    }
    
    var bgActionPrimaryRest: Color {
        .compound.bgActionPrimaryRest
    }
    
    var bgCriticalPrimary: Color {
        .compound.bgCriticalPrimary
    }
    
    var iconPrimary: Color {
        .compound.iconPrimary
    }
    
    var iconQuaternary: Color {
        .compound.iconQuaternary
    }
    
    var iconAccentPrimary: Color {
        .compound.iconAccentPrimary
    }
    
    var iconCriticalPrimary: Color {
        .compound.iconCriticalPrimary
    }
    
    var iconOnSolidPrimary: Color {
        .compound.iconOnSolidPrimary
    }
    
    var textPrimary: Color {
        .compound.textPrimary
    }
    
    var textSecondary: Color {
        .compound.textSecondary
    }
    
    var textCriticalPrimary: Color {
        .compound.textCriticalPrimary
    }
    
    var borderSuccessSubtle: Color {
        .compound.borderSuccessSubtle
    }
    
    var borderInteractiveSecondary: Color {
        .compound.borderInteractiveSecondary
    }
    
    var bodySM: Font {
        .compound.bodySM
    }
    
    var bodySMSemibold: Font {
        .compound.bodySMSemibold
    }
    
    var bodyLGSemibold: Font {
        .compound.bodyLGSemibold
    }
}

struct NativeCallCompoundIcons: ElementCallIconRendering {
    func icon(_ icon: ElementCallIcon, size: ElementCallIconSize, relativeTo textStyle: ElementCallTextStyle?) -> AnyView {
        // CompoundIcon handles Dynamic Type scaling, which is why the package asks for a text style
        // rather than a point size.
        AnyView(CompoundIcon(Self.keyPath(for: icon), size: Self.size(for: size), relativeTo: Self.font(for: textStyle)))
    }
    
    private static func keyPath(for icon: ElementCallIcon) -> KeyPath<CompoundIcons, Image> {
        switch icon {
        case .endCall: \.endCall
        case .micOn: \.micOnSolid
        case .micOff: \.micOffSolid
        case .videoCall: \.videoCallSolid
        case .videoCallOff: \.videoCallOffSolid
        case .switchCamera: \.switchCameraSolid
        case .shareScreen: \.shareScreenSolid
        case .volumeOn: \.volumeOnSolid
        case .volumeOff: \.volumeOffSolid
        case .raisedHand: \.raisedHandSolid
        case .userProfile: \.userProfileSolid
        case .overflow: \.overflowHorizontal
        case .collapse: \.collapse
        }
    }
    
    private static func size(for size: ElementCallIconSize) -> CompoundIcon.Size {
        switch size {
        case .xSmall: .xSmall
        case .small: .small
        case .medium: .medium
        }
    }
    
    // Not redundant despite the target's default isolation: a static member of a type conforming to
    // a nonisolated, Sendable port is nonisolated, and `Font.compound` is main actor-isolated.
    @MainActor
    private static func font(for textStyle: ElementCallTextStyle?) -> Font {
        switch textStyle {
        case .bodySM: .compound.bodySM
        case .bodySMSemibold: .compound.bodySMSemibold
        case .bodyLGSemibold: .compound.bodyLGSemibold
        case nil: .compound.bodyMD
        }
    }
}

/// Keeps avatars looking like the rest of the app, and keeps media loading out of the package.
struct NativeCallCompoundAvatars: ElementCallAvatarRendering {
    let mediaProvider: MediaProviderProtocol?
    
    func avatar(userID: String, displayName: String?, avatarURL: URL?, size: ElementCallAvatarSize) -> AnyView {
        AnyView(LoadableAvatarImage(url: avatarURL,
                                    name: displayName,
                                    contentID: userID,
                                    avatarSize: size == .thumbnail ? .user(on: .roomDetails) : .user(on: .memberDetails),
                                    mediaProvider: mediaProvider))
    }
}
