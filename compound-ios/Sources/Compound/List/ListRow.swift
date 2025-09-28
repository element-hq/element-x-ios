//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

public enum ListRowPadding {
    public static let horizontal: CGFloat = 16
    public static let vertical: CGFloat = 13
    public static let insets = EdgeInsets(top: vertical,
                                          leading: horizontal,
                                          bottom: vertical,
                                          trailing: horizontal)
    
    public static let textFieldInsets = EdgeInsets(top: 11,
                                                   leading: horizontal,
                                                   bottom: 11,
                                                   trailing: horizontal)
}

public struct ListRow<Icon: View, DetailsIcon: View, CustomContent: View, SelectionValue: Hashable>: View {
    @Environment(\.isEnabled) private var isEnabled
    
    let label: ListRowLabel<Icon>
    let details: ListRowDetails<DetailsIcon>?
    
    public enum Kind<CustomContent: View, SelectionValue: Hashable> {
        case label
        case button(action: () -> Void)
        case navigationLink(action: () -> Void)
        case picker(selection: Binding<SelectionValue>, items: [(title: String, tag: SelectionValue)])
        case toggle(Binding<Bool>)
        case inlinePicker(selection: Binding<SelectionValue>, items: [(title: String, tag: SelectionValue)])
        case selection(isSelected: Bool, action: () -> Void)
        case multiSelection(isSelected: Bool, action: () -> Void)
        case textField(text: Binding<String>, axis: Axis?)
        case secureField(text: Binding<String>)
        
        case custom(() -> CustomContent)
        
        public static func textField(text: Binding<String>) -> Self {
            .textField(text: text, axis: nil)
        }
    }
    
    let kind: Kind<CustomContent, SelectionValue>
    
    public var body: some View {
        rowContent
            .buttonStyle(ListRowButtonStyle())
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.compound.bgCanvasDefaultLevel1)
            .listRowSeparatorTint(.compound._borderInteractiveSecondaryAlpha)
    }
    
    @ViewBuilder
    var rowContent: some View {
        switch kind {
        case .label:
            RowContent(details: details) { label }
        case .button(let action):
            Button(action: action) {
                RowContent(details: details) { label }
            }
        case .navigationLink(let action):
            Button(action: action) {
                RowContent(details: details, accessory: .navigationLink) { label }
            }
        case .picker(let selection, let items):
            HStack(spacing: 0) {
                label
                Spacer()
                // Note: VoiceOver label already provided.
                Picker("", selection: selection) {
                    ForEach(items, id: \.tag) { item in
                        Text(item.title)
                            .tag(item.tag)
                    }
                }
                .labelsHidden()
                .padding(.vertical, -10)
                .padding(.trailing, ListRowPadding.horizontal)
            }
            .accessibilityElement(children: .combine)
        case .toggle(let binding):
            HStack(spacing: 0) {
                label
                Spacer()
                HStack(spacing: ListRowTrailingSectionSpacing.horizontal) {
                    if let details {
                        ListRowTrailingSection(details)
                    }
                    
                    // Note: VoiceOver label already provided.
                    Toggle("", isOn: binding)
                        .toggleStyle(.compound)
                        .labelsHidden()
                        .padding(.vertical, -10)
                }
            }
            .padding(.trailing, ListRowPadding.horizontal)
            .accessibilityElement(children: .combine)
        case .inlinePicker(let selection, let items):
            ListInlinePicker(title: label.title ?? "",
                             selection: selection,
                             items: items,
                             isWaiting: details?.isWaiting ?? false)
        case .selection(let isSelected, let action):
            Button(action: action) {
                RowContent(details: details, accessory: .selection(isSelected)) { label }
            }
            .isToggle()
        case .multiSelection(let isSelected, let action):
            Button(action: action) {
                RowContent(details: details, accessory: .multiSelection(isSelected)) { label }
            }
            .isToggle()
        case .textField(let text, let axis):
            TextField(text: text, axis: axis) {
                Text(label.title ?? "")
                    .compoundTextFieldPlaceholder()
            }
            .tint(.compound.iconAccentTertiary)
            .foregroundStyle(isEnabled ? .compound.textPrimary : .compound.textDisabled)
            .listRowInsets(ListRowPadding.textFieldInsets)
        case .secureField(let text):
            SecureField(text: text) {
                Text(label.title ?? "")
                    .compoundTextFieldPlaceholder()
            }
            .tint(.compound.iconAccentTertiary)
            .foregroundStyle(isEnabled ? .compound.textPrimary : .compound.textDisabled)
            .listRowInsets(ListRowPadding.textFieldInsets)
        
        case .custom(let content):
            content()
        }
    }
}

// MARK: - Initialisers

// Normal row with a details icon
public extension ListRow where CustomContent == EmptyView {
    init(label: ListRowLabel<Icon>,
         details: ListRowDetails<DetailsIcon>? = nil,
         kind: Kind<CustomContent, SelectionValue>) {
        self.label = label
        self.details = details
        self.kind = kind
    }
    
    init(label: ListRowLabel<Icon>,
         details: ListRowDetails<DetailsIcon>? = nil,
         kind: Kind<CustomContent, SelectionValue>) where SelectionValue == String {
        self.label = label
        self.details = details
        self.kind = kind
    }
}

// Normal row without a details icon.
public extension ListRow where DetailsIcon == EmptyView, CustomContent == EmptyView {
    init(label: ListRowLabel<Icon>,
         details: ListRowDetails<DetailsIcon>? = nil,
         kind: Kind<CustomContent, SelectionValue>) {
        self.label = label
        self.details = details
        self.kind = kind
    }
    
    init(label: ListRowLabel<Icon>,
         details: ListRowDetails<DetailsIcon>? = nil,
         kind: Kind<CustomContent, SelectionValue>) where SelectionValue == String {
        self.label = label
        self.details = details
        self.kind = kind
    }
}

// Custom row without a label or details label.
public extension ListRow where Icon == EmptyView, DetailsIcon == EmptyView {
    init(kind: Kind<CustomContent, SelectionValue>) {
        self.label = ListRowLabel()
        self.details = nil
        self.kind = kind
    }
    
    init(kind: Kind<CustomContent, SelectionValue>) where SelectionValue == String {
        self.label = ListRowLabel()
        self.details = nil
        self.kind = kind
    }
}

/// The standard content for labels, and button based rows.
///
/// This doesn't use `LabeledContent` as that will happily build using an `EmptyView`
/// in the content. This creates an issue where the label ends up hidden to VoiceOver,
/// presumably because SwiftUI thinks that the row doesn't contain any content.
private struct RowContent<Label: View, DetailsIcon: View>: View {
    let details: ListRowDetails<DetailsIcon>?
    var accessory: ListRowAccessory?
    let label: () -> Label
    
    var body: some View {
        HStack(spacing: ListRowTrailingSectionSpacing.horizontal) {
            label()
                .frame(maxWidth: .infinity)
            
            if details != nil || accessory != nil {
                ListRowTrailingSection(details, accessory: accessory)
            }
        }
        .frame(maxHeight: .infinity)
        .padding(.trailing, ListRowPadding.horizontal)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Helpers

private extension TextField {
    /// Creates a text field with an optional preferred axis. Hard coding a default resulted
    /// in the underlying component always being a `UITextView` during introspection.
    /// This initialiser does the right thing when not supplying an axis in `ListRow.Kind`.
    init(text: Binding<String>, axis: Axis?, label: () -> Label) {
        if let axis {
            self.init(text: text, axis: axis, label: label)
        } else {
            self.init(text: text, label: label)
        }
    }
}

private extension Button {
    /// Adds the `isToggle` accessibility trait on iOS 17+
    @ViewBuilder func isToggle() -> some View {
        if #available(iOS 17.0, *) {
            accessibilityAddTraits(.isToggle)
        } else {
            self
        }
    }
}

// MARK: - Previews

public struct ListRow_Previews: PreviewProvider, TestablePreview {
    public static var previews: some View {
        Form {
            Section {
                labels
                buttons
                pickers
                toggles
                selection
                actionButtons
                plainButton
            }
            
            centeredActionButtonSections
            descriptionLabelSection
            avatarSection
            othersSection
        }
        .compoundList()
        .frame(idealHeight: 2100) // Snapshot height
        .previewLayout(.sizeThatFits)
    }
    
    static var labels: some View {
        ListRow(label: .default(title: "Label",
                                description: "Non-interactive item",
                                systemIcon: .squareDashed),
                details: .label(title: "Content",
                                systemIcon: .squareDashed,
                                isWaiting: true),
                kind: .label)
    }
    
    @ViewBuilder static var buttons: some View {
        ListRow(label: .default(title: "Title",
                                description: "Description…",
                                systemIcon: .squareDashed),
                kind: .button { print("I was tapped!") })
        ListRow(label: .default(title: "Title",
                                systemIcon: .squareDashed),
                kind: .button { print("I was tapped!") })
        ListRow(label: .default(title: "Destructive",
                                systemIcon: .squareDashed,
                                role: .destructive),
                kind: .button { print("I will delete things!") })
        ListRow(label: .default(title: "Title",
                                description: "Description…",
                                systemIcon: .squareDashed),
                details: .label(title: "Details", systemIcon: .squareDashed),
                kind: .navigationLink { print("Perform navigation!") })
        ListRow(label: .default(title: "Title",
                                systemIcon: .squareDashed),
                kind: .navigationLink { print("Perform navigation!") })
    }
    
    @ViewBuilder static var pickers: some View {
        ListRow(label: .default(title: "Title",
                                description: "Description…",
                                systemIcon: .squareDashed),
                kind: .picker(selection: .constant(0),
                              items: [(title: "Item 1", tag: 0),
                                      (title: "Item 2", tag: 1),
                                      (title: "Item 3", tag: 2)]))
        ListRow(label: .default(title: "Very very very very very very long title",
                                description: "Description…",
                                systemIcon: .squareDashed),
                kind: .picker(selection: .constant(0),
                              items: [(title: "Item 1", tag: 0),
                                      (title: "Item 2", tag: 1),
                                      (title: "Item 3", tag: 2)]))
        ListRow(label: .default(title: "Title", systemIcon: .squareDashed),
                kind: .picker(selection: .constant("Item 1"),
                              items: [(title: "Item 1", tag: "Item 1"),
                                      (title: "Item 2", tag: "Item 2"),
                                      (title: "Item 3", tag: "Item 3")]))
    }
    
    @ViewBuilder static var toggles: some View {
        ListRow(label: .default(title: "Title",
                                description: "Description…",
                                systemIcon: .squareDashed),
                kind: .toggle(.constant(true)))
        ListRow(label: .default(title: "Very very very very very very very long title",
                                description: "Description…",
                                systemIcon: .squareDashed),
                kind: .toggle(.constant(true)))
        ListRow(label: .default(title: "Title", systemIcon: .squareDashed),
                kind: .toggle(.constant(true)))
        ListRow(label: .default(title: "Title", systemIcon: .squareDashed),
                details: .isWaiting(true),
                kind: .toggle(.constant(false)))
    }
    
    @ViewBuilder static var selection: some View {
        ListRow(label: .default(title: "Title",
                                description: "Description…",
                                systemIcon: .squareDashed),
                details: .title("Content"),
                kind: .selection(isSelected: true) {
            print("I was tapped!")
        })
        ListRow(label: .default(title: "Title",
                                systemIcon: .squareDashed),
                details: .title("Content"),
                kind: .selection(isSelected: true) {
            print("I was tapped!")
        })
        
        ListRow(label: .plain(title: "Title"),
                kind: .inlinePicker(selection: .constant("Item 1"),
                                    items: [(title: "Item 1", tag: "Item 1"),
                                            (title: "Item 2", tag: "Item 2"),
                                            (title: "Item 3", tag: "Item 3")]))
    }
    
    @ViewBuilder static var actionButtons: some View {
        ListRow(label: .action(title: "Title",
                               systemIcon: .squareDashed),
                kind: .button { print("I was tapped!") })
        ListRow(label: .action(title: "Title",
                               systemIcon: .squareDashed,
                               role: .destructive),
                kind: .button { print("I was tapped!") })
        ListRow(label: .action(title: "Title",
                               systemIcon: .squareDashed),
                kind: .button { print("I was tapped!") })
        .disabled(true)
    }
    
    static var plainButton: some View {
        ListRow(label: .plain(title: "Title"),
                kind: .button { print("I was tapped!") })
    }
    
    @ViewBuilder static var centeredActionButtonSections: some View {
        Section {
            ListRow(label: .centeredAction(title: "Title",
                                           systemIcon: .squareDashed),
                    kind: .button { print("I was tapped!") })
        }
        
        Section {
            ListRow(label: .centeredAction(title: "Title",
                                           systemIcon: .squareDashed,
                                           role: .destructive),
                    kind: .button { print("I was tapped!") })
        }
        
        Section {
            ListRow(label: .centeredAction(title: "Title",
                                           systemIcon: .squareDashed),
                    kind: .button { print("I was tapped!") })
            .disabled(true)
        }
    }
    
    static var descriptionLabelSection: some View {
        Section {
            ListRow(label: .description("This is a row in the list, with a multiline description but it doesn't have either an icon or a title, just this text here."),
                    kind: .label)
        }
    }
    
    static var avatarSection: some View {
        Section {
            ListRow(label: .avatar(title: "Alice",
                                   description: "@alice:element.io",
                                   icon: Circle().foregroundStyle(.compound.decorativeColors[0].background)),
                    kind: .multiSelection(isSelected: true) { })
            ListRow(label: .avatar(title: "Bob",
                                   description: "@bob:element.io",
                                   icon: Circle().foregroundStyle(.compound.decorativeColors[1].background)),
                    kind: .multiSelection(isSelected: false) { })
            ListRow(label: .avatar(title: "Dan",
                                   status: "Pending",
                                   description: "@dan:element.io",
                                   icon: Circle().foregroundStyle(.compound.decorativeColors[3].background)),
                    kind: .multiSelection(isSelected: false) { })
                .disabled(true)
            ListRow(label: .avatar(title: "@charlie:fake.com",
                                   description: "This user can't be found, so the invite may not be received.",
                                   icon: Circle().foregroundStyle(.compound.decorativeColors[2].background),
                                   role: .error),
                    kind: .button { })
        }
    }
    
    @ViewBuilder static var othersSection: some View {
        Section {
            ListRow(kind: .custom {
                Text("This is a custom row")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
            })
            ListRow(label: .plain(title: "Placeholder"),
                    kind: .textField(text: .constant("This is a disabled text field")))
            .disabled(true)
            ListRow(label: .plain(title: "Placeholder"),
                    kind: .textField(text: .constant(""), axis: .vertical))
            .lineLimit(4...)
            ListRow(label: .plain(title: "Password"),
                    kind: .secureField(text: .constant("p4ssw0rd")))
        }
    }
}

struct ListRowLoadingSelection_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        Form {
            ListRow(label: .plain(title: "Selected",
                                  description: "This is a long multiline description which shows what happens when wrapping with a details view and selection, specifically, an activity indicator in the details."),
                    details: .isWaiting(false),
                    kind: .selection(isSelected: true) { })
            ListRow(label: .plain(title: "Unselected",
                                  description: "This is a long multiline description which shows what happens when wrapping with a details view and selection, specifically, an activity indicator in the details."),
                    details: .isWaiting(false),
                    kind: .selection(isSelected: false) { })
            ListRow(label: .plain(title: "Unselected & Loading",
                                  description: "This is a long multiline description which shows what happens when wrapping with a details view and selection, specifically, an activity indicator in the details."),
                    details: .isWaiting(true),
                    kind: .selection(isSelected: false) { })
        }
        .compoundList()
    }
}
