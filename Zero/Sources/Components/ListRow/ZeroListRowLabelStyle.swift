import CompoundDesignTokens
import Compound
import SFSafeSymbols
import SwiftUI

/// The main label style used in the leading section of `ListRow`.
struct ZeroListRowLabelStyle: LabelStyle {
    let iconAlignment: VerticalAlignment
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: iconAlignment, spacing: 16) {
            configuration.icon
            configuration.title
        }
    }
}

/// The label style used in `ListRow` for centred buttons.
struct ZeroListRowCenteredLabelStyle: LabelStyle {
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
struct ZeroListRowAvatarLabelStyle: LabelStyle {
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

public struct ZeroListRowLabel<Icon: View>: View {
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
        .padding(.leading, ZeroListRowPadding.horizontal)
        .padding(.vertical, ZeroListRowPadding.vertical)
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
        .labelStyle(ZeroListRowLabelStyle(iconAlignment: iconAlignment))
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
        .labelStyle(ZeroListRowCenteredLabelStyle())
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
    
    var avatarBody: some View {
        Label {
            titleAndDescription
        } icon: {
            icon // Layout handled by the style.
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .labelStyle(ZeroListRowAvatarLabelStyle())
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
                        CompoundIcon(\.error, size: .xSmall, relativeTo: .compound.bodySM)
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
                                 role: ZeroListRowLabel.Role? = nil,
                                 iconAlignment: VerticalAlignment = .center) -> ZeroListRowLabel {
        ZeroListRowLabel(title: title,
                     description: description,
                     icon: icon,
                     role: role,
                     iconAlignment: iconAlignment)
    }
    
    public static func `default`(title: String,
                                 description: String? = nil,
                                 icon: KeyPath<CompoundIcons, Image>,
                                 role: ZeroListRowLabel.Role? = nil,
                                 iconAlignment: VerticalAlignment = .center) -> ZeroListRowLabel where Icon == CompoundIcon {
        .default(title: title,
                 description: description,
                 icon: CompoundIcon(icon),
                 role: role,
                 iconAlignment: iconAlignment)
    }
    
    public static func `default`(title: String,
                                 description: String? = nil,
                                 systemIcon: SFSymbol,
                                 role: ZeroListRowLabel.Role? = nil,
                                 iconAlignment: VerticalAlignment = .center) -> ZeroListRowLabel where Icon == Image {
        .default(title: title,
                 description: description,
                 icon: Image(systemSymbol: systemIcon),
                 role: role,
                 iconAlignment: iconAlignment)
    }
    
    public static func action(title: String,
                              icon: Icon,
                              role: ZeroListRowLabel.Role? = nil) -> ZeroListRowLabel {
        ZeroListRowLabel(title: title,
                     icon: icon,
                     role: role,
                     hideIconBackground: true)
    }
    
    public static func action(title: String,
                              icon: KeyPath<CompoundIcons, Image>,
                              role: ZeroListRowLabel.Role? = nil) -> ZeroListRowLabel where Icon == CompoundIcon {
        .action(title: title, icon: CompoundIcon(icon), role: role)
    }
    
    public static func action(title: String,
                              systemIcon: SFSymbol,
                              role: ZeroListRowLabel.Role? = nil) -> ZeroListRowLabel where Icon == Image {
        .action(title: title, icon: Image(systemSymbol: systemIcon), role: role)
    }
    
    public static func centeredAction(title: String,
                                      icon: Icon,
                                      role: ZeroListRowLabel.Role? = nil) -> ZeroListRowLabel {
        ZeroListRowLabel(title: title,
                     icon: icon,
                     role: role,
                     hideIconBackground: true,
                     layout: .centered)
    }
    
    public static func centeredAction(title: String,
                                      icon: KeyPath<CompoundIcons, Image>,
                                      role: ZeroListRowLabel.Role? = nil) -> ZeroListRowLabel where Icon == CompoundIcon {
        .centeredAction(title: title, icon: CompoundIcon(icon), role: role)
    }
    
    public static func centeredAction(title: String,
                                      systemIcon: SFSymbol,
                                      role: ZeroListRowLabel.Role? = nil) -> ZeroListRowLabel where Icon == Image {
        .centeredAction(title: title, icon: Image(systemSymbol: systemIcon), role: role)
    }
    
    public static func plain(title: String,
                             description: String? = nil,
                             role: ZeroListRowLabel.Role? = nil) -> ZeroListRowLabel where Icon == EmptyView {
        ZeroListRowLabel(title: title, description: description, role: role, hideIconBackground: true)
    }
    
    public static func description(_ description: String) -> ZeroListRowLabel where Icon == EmptyView {
        ZeroListRowLabel(description: description)
    }
    
    /// A label that displays an avatar as it's icon, such as a user profile row or for a room picker.
    public static func avatar(title: String,
                              status: String? = nil,
                              description: String? = nil,
                              icon: Icon,
                              role: ZeroListRowLabel.Role? = nil) -> ZeroListRowLabel {
        ZeroListRowLabel(title: title,
                     status: status,
                     description: description,
                     icon: icon,
                     role: role,
                     layout: .avatar)
    }
}
