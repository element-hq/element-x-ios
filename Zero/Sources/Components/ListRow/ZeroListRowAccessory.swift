import Compound
import SwiftUI

/// A view to be added on the trailing edge of a form row.
public struct ZeroListRowAccessory: View {
    @Environment(\.isEnabled) private var isEnabled
    
    enum Kind {
        /// A navigation chevron.
        case navigationLink
        /// A checkmark.
        case selected
        /// ``selected`` but invisible to reserve space.
        case unselected
        /// A circular checkmark.
        case multiSelected
        /// An empty circle.
        case multiUnselected
    }
    
    /// A chevron to indicate that the button pushes another screen.
    public static var navigationLink: Self {
        Self(kind: .navigationLink)
    }
    
    /// A checkmark (or reserved space) to indicate that the row is selected.
    public static func selection(_ isSelected: Bool) -> Self {
        Self(kind: isSelected ? .selected : .unselected)
    }
    
    /// A circular checkmark (or empty circle) to indicate that the row is one of multiple selected.
    public static func multiSelection(_ isSelected: Bool) -> Self {
        Self(kind: isSelected ? .multiSelected : .multiUnselected)
    }
    
    let kind: Kind
    
    /// Negative padding added to prevent the accessory interfering with the row's padding.
    private var verticalPaddingFix: CGFloat { -4 }
    /// Absolute bodge until we have the circle icon in Compound.
    @ScaledMetric private var circleOverlayInsets = 5
    
    public var body: some View {
        switch kind {
        case .navigationLink:
            CompoundIcon(\.chevronRight)
                .foregroundColor(.compound.iconTertiaryAlpha)
                .flipsForRightToLeftLayoutDirection(true)
        case .selected:
            CompoundIcon(\.check)
                .foregroundColor(isEnabled ? .compound.iconAccentPrimary : .compound.iconDisabled)
                .accessibilityAddTraits(.isSelected)
                .padding(.vertical, verticalPaddingFix)
        case .unselected:
            CompoundIcon(\.check)
                .hidden()
                .padding(.vertical, verticalPaddingFix)
        case .multiSelected:
            CompoundIcon(\.checkCircleSolid)
                .foregroundColor(isEnabled ? .compound.iconSuccessPrimary : .compound.iconDisabled)
                .accessibilityAddTraits(.isSelected)
                .padding(.vertical, verticalPaddingFix)
        case .multiUnselected:
            CompoundIcon(\.circle)
                .foregroundColor(isEnabled ? .compound.borderInteractivePrimary : .compound.borderDisabled)
                .padding(.vertical, verticalPaddingFix)
        }
    }
}
