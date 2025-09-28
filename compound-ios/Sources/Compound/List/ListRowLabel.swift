//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CompoundDesignTokens
import SFSafeSymbols
import SwiftUI

/// The main label style used in the leading section of `ListRow`.
struct ListRowLabelStyle: LabelStyle {
    let iconAlignment: VerticalAlignment
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: iconAlignment, spacing: 16) {
            configuration.icon
            configuration.title
        }
    }
}

/// The label style used in `ListRow` for centred buttons.
struct ListRowCenteredLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 8) {
            configuration.icon
            configuration.title
        }
    }
}

/// The label style used in the leading section of `ListRow` that show an avatar as the icon.
///
/// Unlike the other styles, this one sizes the avatar internally.
struct ListRowAvatarLabelStyle: LabelStyle {
    @ScaledMetric private var avatarSize = 32.0
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 16) {
            configuration.icon
                .frame(width: avatarSize, height: avatarSize)
                .padding(.vertical, -5) // Don't allow the avatar to size the row.
            configuration.title
        }
    }
}

public struct ListRowLabel<Icon: View>: View {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.lineLimit) private var lineLimit
    @ScaledMetric private var iconSize = 30.0
    
    var title: String?
    var status: String?
    var description: String?
    var icon: Icon?
    
    var role: Role?
    public enum Role {
        /// A role that indicates a destructive action.
        case destructive
        /// A role that indicates an error.
        ///
        /// The label should contain a description when using this role.
        case error
    }
    
    var iconAlignment: VerticalAlignment = .center
    var hideIconBackground: Bool = false
    
    enum Layout { case `default`, centered, avatar }
    var layout: Layout = .default
    
    var titleColor: Color {
        guard isEnabled else { return .compound.textDisabled }
        return role == .destructive ? .compound.textCriticalPrimary : .compound.textPrimary
    }
    var titleLineLimit: Int? { layout == .avatar ? 1 : lineLimit }
    
    var statusColor: Color {
        isEnabled ? .compound.textSecondary : .compound.textDisabled
    }
    
    var descriptionColor: Color {
        isEnabled ? .compound.textSecondary : .compound.textDisabled
    }
    var descriptionLineLimit: Int? {
        guard layout == .avatar else { return lineLimit }
        return role != .error ? 1 : lineLimit
    }
    
    var iconForegroundColor: Color {
        guard isEnabled else { return .compound.iconTertiaryAlpha }
        if role == .destructive { return .compound.textCriticalPrimary }
        return hideIconBackground ? .compound.iconPrimary : .compound.iconTertiaryAlpha
    }
    
    var iconBackgroundColor: Color {
        if hideIconBackground { return .clear }
        guard isEnabled else { return .compound._bgSubtleSecondaryAlpha }
        return role == .destructive ? .compound._bgCriticalSubtleAlpha : .compound._bgSubtleSecondaryAlpha
    }
    
    public var body: some View {
        Group {
            switch layout {
            case .default:
                defaultBody
            case .centered:
                centeredBody
            case .avatar:
                avatarBody
            }
        }
        .padding(.leading, ListRowPadding.horizontal)
        .padding(.vertical, ListRowPadding.vertical)
    }
    
    var defaultBody: some View {
        Label {
            titleAndDescription
        } icon: {
            icon
                .foregroundColor(iconForegroundColor)
                .frame(width: iconSize, height: iconSize)
                .background(iconBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.vertical, -4) // Don't allow the background to size the row.
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .labelStyle(ListRowLabelStyle(iconAlignment: iconAlignment))
    }
    
    var centeredBody: some View {
        Label {
            if let title {
                Text(title)
                    .font(.compound.bodyLG)
                    .foregroundColor(titleColor)
            }
        } icon: {
            icon
                .foregroundColor(iconForegroundColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .labelStyle(ListRowCenteredLabelStyle())
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
    
    var avatarBody: some View {
        Label {
            titleAndDescription
        } icon: {
            icon // Layout handled by the style.
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .labelStyle(ListRowAvatarLabelStyle())
    }
    
    var titleAndDescription: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let title {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .font(.compound.bodyLG)
                        .foregroundColor(titleColor)
                        .lineLimit(titleLineLimit)
                    
                    // Status is only available in the avatar init which requires a title,
                    // so no need to worry about the outer `if let` being nil in this instance.
                    if let status {
                        Text(status)
                            .font(.compound.bodySM)
                            .foregroundColor(statusColor)
                            .lineLimit(1)
                    }
                }
            }
            
            if let description {
                HStack(alignment: .top, spacing: 4) {
                    if role == .error {
                        CompoundIcon(\.errorSolid, size: .xSmall, relativeTo: .compound.bodySM)
                            .foregroundStyle(.compound.iconCriticalPrimary)
                    }
                    
                    Text(description)
                        .font(.compound.bodySM)
                        .foregroundColor(descriptionColor)
                        .lineLimit(descriptionLineLimit)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Initialisers
    
    public static func `default`(title: String,
                                 description: String? = nil,
                                 icon: Icon,
                                 role: ListRowLabel.Role? = nil,
                                 iconAlignment: VerticalAlignment = .center) -> ListRowLabel {
        ListRowLabel(title: title,
                     description: description,
                     icon: icon,
                     role: role,
                     iconAlignment: iconAlignment)
    }
    
    public static func `default`(title: String,
                                 description: String? = nil,
                                 icon: KeyPath<CompoundIcons, Image>,
                                 role: ListRowLabel.Role? = nil,
                                 iconAlignment: VerticalAlignment = .center) -> ListRowLabel where Icon == CompoundIcon {
        .default(title: title,
                 description: description,
                 icon: CompoundIcon(icon),
                 role: role,
                 iconAlignment: iconAlignment)
    }
    
    public static func `default`(title: String,
                                 description: String? = nil,
                                 systemIcon: SFSymbol,
                                 role: ListRowLabel.Role? = nil,
                                 iconAlignment: VerticalAlignment = .center) -> ListRowLabel where Icon == Image {
        .default(title: title,
                 description: description,
                 icon: Image(systemSymbol: systemIcon),
                 role: role,
                 iconAlignment: iconAlignment)
    }
    
    public static func action(title: String,
                              icon: Icon,
                              role: ListRowLabel.Role? = nil) -> ListRowLabel {
        ListRowLabel(title: title,
                     icon: icon,
                     role: role,
                     hideIconBackground: true)
    }
    
    public static func action(title: String,
                              icon: KeyPath<CompoundIcons, Image>,
                              role: ListRowLabel.Role? = nil) -> ListRowLabel where Icon == CompoundIcon {
        .action(title: title, icon: CompoundIcon(icon), role: role)
    }
    
    public static func action(title: String,
                              systemIcon: SFSymbol,
                              role: ListRowLabel.Role? = nil) -> ListRowLabel where Icon == Image {
        .action(title: title, icon: Image(systemSymbol: systemIcon), role: role)
    }
    
    public static func centeredAction(title: String,
                                      icon: Icon,
                                      role: ListRowLabel.Role? = nil) -> ListRowLabel {
        ListRowLabel(title: title,
                     icon: icon,
                     role: role,
                     hideIconBackground: true,
                     layout: .centered)
    }
    
    public static func centeredAction(title: String,
                                      icon: KeyPath<CompoundIcons, Image>,
                                      role: ListRowLabel.Role? = nil) -> ListRowLabel where Icon == CompoundIcon {
        .centeredAction(title: title, icon: CompoundIcon(icon), role: role)
    }
    
    public static func centeredAction(title: String,
                                      systemIcon: SFSymbol,
                                      role: ListRowLabel.Role? = nil) -> ListRowLabel where Icon == Image {
        .centeredAction(title: title, icon: Image(systemSymbol: systemIcon), role: role)
    }
    
    public static func plain(title: String,
                             description: String? = nil,
                             role: ListRowLabel.Role? = nil) -> ListRowLabel where Icon == EmptyView {
        ListRowLabel(title: title, description: description, role: role, hideIconBackground: true)
    }
    
    public static func description(_ description: String) -> ListRowLabel where Icon == EmptyView {
        ListRowLabel(description: description)
    }
    
    /// A label that displays an avatar as it's icon, such as a user profile row or for a room picker.
    public static func avatar(title: String,
                              status: String? = nil,
                              description: String? = nil,
                              icon: Icon,
                              role: ListRowLabel.Role? = nil) -> ListRowLabel {
        ListRowLabel(title: title,
                     status: status,
                     description: description,
                     icon: icon,
                     role: role,
                     layout: .avatar)
    }
}

// MARK: - Previews

struct ListRowLabel_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        Form {
            Section {
                Group {
                    ListRowLabel.default(title: "Person", icon: Image(systemName: "person"))
                    
                    ListRowLabel.default(title: "Help",
                                         description: "Supporting text",
                                         systemIcon: .questionmarkCircle)
                    
                    ListRowLabel.default(title: "Trash",
                                         icon: Image(systemName: "trash"),
                                         role: .destructive)
                }
                
                Group {
                    ListRowLabel.action(title: "Camera",
                                        icon: Image(systemName: "camera"))
                    
                    ListRowLabel.action(title: "Remove",
                                        icon: Image(systemName: "person.badge.minus"),
                                        role: .destructive)
                    
                    ListRowLabel.centeredAction(title: "Person",
                                                icon: Image(systemName: "person"))
                    ListRowLabel.centeredAction(title: "Remove",
                                                systemIcon: .personBadgeMinus,
                                                role: .destructive)
                }
                
                Group {
                    ListRowLabel.plain(title: "Person")
                    ListRowLabel.plain(title: "Remove",
                                       role: .destructive)
                    ListRowLabel.plain(title: "Plain", description: "Description")
                }
                
                ListRowLabel.description("This is a row in the list, that only contains a description and doesn't have either an icon or a title.")
            }
            .listRowInsets(EdgeInsets())
            
            Section {
                ListRowLabel.avatar(title: "Alice",
                                    description: "@alice:example.com",
                                    icon: Circle().foregroundStyle(.compound.decorativeColors[0].background))
                ListRowLabel.avatar(title: "Alice",
                                    status: "Pending",
                                    description: "@alice:example.com",
                                    icon: Circle().foregroundStyle(.compound.decorativeColors[0].background))
                ListRowLabel.avatar(title: "@bob:idontexist.com",
                                    description: "This user can't be found, so the invite may not be received.",
                                    icon: Circle().foregroundStyle(.compound.decorativeColors[0].background),
                                    role: .error)
            }
            .listRowInsets(EdgeInsets())
            
            Section {
                ListRow(label: .description("This is a row in the list, with a multiline description but it doesn't have either an icon or a title, just this text here."),
                        kind: .label)
            }
        }
        .compoundList()
        .frame(idealHeight: 1000) // Snapshot height
        .previewLayout(.sizeThatFits)
    }
}
