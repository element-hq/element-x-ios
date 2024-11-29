import SwiftUI

/// The spacing used inside of a ListRow
enum ZeroListRowTrailingSectionSpacing {
    static let horizontal = 8.0
}

/// The style applied to the details label in a list row's trailing section.
private struct ZeroListRowDetailsLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: ZeroListRowTrailingSectionSpacing.horizontal) {
            configuration.title
                .foregroundColor(.compound.textSecondary)
            configuration.icon
                .foregroundColor(.compound.iconPrimary)
        }
        .font(.compound.bodyLG)
    }
}

/// The view shown to the right of the `ListRowLabel` inside of a `ListRow`.
/// This consists of both the `ListRowDetails` and the `ListRowAccessory`.
public struct ZeroListRowTrailingSection<Icon: View>: View {
    @Environment(\.isEnabled) private var isEnabled

    private var title: String?
    private var icon: Icon?
    private var counter: Int?
    private var isWaiting = false
    private var accessory: ZeroListRowAccessory?
    
    @ScaledMetric private var iconSize = 24
    private var hideAccessory: Bool { isWaiting && accessory?.kind == .unselected }
    
    init(_ details: ZeroListRowDetails<Icon>?, accessory: ZeroListRowAccessory? = nil) {
        title = details?.title
        icon = details?.icon
        isWaiting = details?.isWaiting ?? false
        counter = details?.counter
        self.accessory = accessory
    }
    
    public var body: some View {
        HStack(spacing: ZeroListRowTrailingSectionSpacing.horizontal) {
            if isWaiting {
                ProgressView()
            }
            
            if title != nil || icon != nil {
                Label {
                    title.map(Text.init)
                } icon: {
                    icon
                }
                .labelStyle(ZeroListRowDetailsLabelStyle())
            }
            
            if let counter {
                Text("\(counter)")
                    .font(.compound.bodyXSSemibold)
                    .foregroundStyle(.compound.textOnSolidPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background { Capsule().fill(isEnabled ? .compound.iconSuccessPrimary : .compound.iconDisabled) }
            }
            
            if let accessory, !hideAccessory {
                accessory
            }
        }
        .frame(minWidth: iconSize)
        .accessibilityElement(children: .combine)
    }
}
