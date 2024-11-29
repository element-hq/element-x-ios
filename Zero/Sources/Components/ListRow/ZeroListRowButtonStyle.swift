import SwiftUI

// TODO: Check if the primitive style is actually needed now the insets are part of ListRow.
// It might still be useful for ListRow(kind: .custom) usage?

/// Default button styling for list rows.
///
/// The primitive style is needed to set the list row insets to `0`. The inner style is then needed
/// to change the background colour depending on whether the button is currently pressed or not.
public struct ZeroListRowButtonStyle: PrimitiveButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        Button(role: configuration.role, action: configuration.trigger) {
            configuration.label
        }
        .buttonStyle(Style())
    }
    
    /// Inner style used to set the pressed background colour.
    struct Style: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .contentShape(Rectangle())
                .background(configuration.isPressed ? Color.compound.bgSubtlePrimary : .zero.bgCanvasDefault)
        }
    }
}
