//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

/// A view to be added on the trailing edge of a form row.
struct FormRowAccessory: View {
    @Environment(\.isEnabled) private var isEnabled
    
    enum Kind {
        case navigationLink
        case progressView
        case singleSelection(isSelected: Bool)
        case multipleSelection(isSelected: Bool)
    }
    
    let kind: Kind
    
    static var navigationLink: Self {
        .init(kind: .navigationLink)
    }
    
    static var progressView: Self {
        .init(kind: .progressView)
    }
    
    static func singleSelection(isSelected: Bool) -> Self {
        .init(kind: .singleSelection(isSelected: isSelected))
    }
    
    static func multipleSelection(isSelected: Bool) -> Self {
        .init(kind: .multipleSelection(isSelected: isSelected))
    }
    
    var body: some View {
        switch kind {
        case .navigationLink:
            Image(systemName: "chevron.forward")
                .font(.compound.bodyMDSemibold)
                .foregroundColor(.compound.iconTertiaryAlpha)
        case .progressView:
            ProgressView()
        case .singleSelection(let isSelected):
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.compound.bodyLG)
                    .foregroundColor(isSelected && isEnabled ? .compound.iconPrimary : .compound.iconTertiary)
                    .accessibilityAddTraits(.isSelected)
            }
        case .multipleSelection(let isSelected):
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.compound.bodyLG)
                .foregroundColor(isSelected && isEnabled ? .compound.iconPrimary : .compound.iconTertiary)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
    }
    
    init(kind: Kind) {
        self.kind = kind
    }
}

/// Default button styling for form rows.
///
/// The primitive style is needed to set the list row insets to `0`. The inner style is then needed
/// to change the background colour depending on whether the button is currently pressed or not.
struct FormButtonStyle: PrimitiveButtonStyle {
    var iconAlignment: VerticalAlignment = .firstTextBaseline
    /// An accessory to be added on the trailing side of the row.
    var accessory: FormRowAccessory?
    
    func makeBody(configuration: Configuration) -> some View {
        Button(action: configuration.trigger) {
            configuration.label
                .labelStyle(FormRowLabelStyle(alignment: iconAlignment, role: configuration.role))
                .frame(maxHeight: .infinity) // Make sure the label fills the cell vertically.
        }
        .buttonStyle(Style(accessory: accessory))
        .listRowInsets(EdgeInsets()) // Remove insets so the background fills the cell.
    }
    
    /// Inner style used to set the pressed background colour.
    private struct Style: ButtonStyle {
        var accessory: FormRowAccessory?
        
        func makeBody(configuration: Configuration) -> some View {
            HStack {
                configuration.label
                    .labelStyle(FormRowLabelStyle(role: configuration.role))
                    .foregroundColor(.compound.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                accessory
            }
            .contentShape(Rectangle())
            .padding(FormRow.insets) // Re-apply the normal insets using padding.
            .background(backgroundColor(for: configuration))
        }
        
        private func backgroundColor(for configuration: Configuration) -> Color {
            switch accessory?.kind {
            case .none, .navigationLink, .progressView:
                return configuration.isPressed ? .compound.bgSubtlePrimary : .compound.bgCanvasDefaultLevel1
            default:
                return .compound.bgCanvasDefaultLevel1
            }
        }
    }
}

/// Small squared action button style for settings screens
struct FormActionButtonStyle: ButtonStyle {
    let title: String
    
    @ScaledMetric private var menuIconSize = 54.0
    
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.label
                .buttonStyle(.plain)
                .foregroundColor(.compound.textPrimary)
                .frame(width: menuIconSize, height: menuIconSize)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(configuration.isPressed ? Color.compound.bgSubtlePrimary : .compound.bgCanvasDefaultLevel1)
                }
            
            Text(title)
                .foregroundColor(.compound.textSecondary)
                .font(.compound.bodyMD)
        }
    }
}

struct FormButtonStyles_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        Form {
            Section {
                Button { } label: {
                    Label("Hello world", systemImage: "globe")
                }
                .buttonStyle(FormButtonStyle())
                
                Button { } label: {
                    Label("Block user", systemImage: "circle.slash")
                }
                .buttonStyle(FormButtonStyle(accessory: .progressView))
                .disabled(true)
                
                Button { } label: {
                    Label("Show something", systemImage: "rectangle.portrait")
                }
                .buttonStyle(FormButtonStyle(accessory: .navigationLink))

                Button(role: .destructive) { } label: {
                    Label("Destroy", systemImage: "trash")
                }
                .buttonStyle(FormButtonStyle())
                
                ShareLink(item: "test")
                    .buttonStyle(FormButtonStyle())
            }
            .compoundFormSection()
            
            Section("Single selection") {
                Button { } label: {
                    Text("Hello world")
                }
                .buttonStyle(FormButtonStyle())
               
                Button { } label: {
                    Text("Selected")
                }
                .buttonStyle(FormButtonStyle(accessory: .singleSelection(isSelected: true)))
                
                Button { } label: {
                    Text("Selected (disabled)")
                }
                .buttonStyle(FormButtonStyle(accessory: .singleSelection(isSelected: true)))
                .disabled(true)
               
                Button { } label: {
                    Text("Unselected")
                }
                .buttonStyle(FormButtonStyle(accessory: .singleSelection(isSelected: false)))
            }
            .compoundFormSection()
            
            Section("Multiple selection") {
                Button { } label: {
                    Text("Hello world")
                }
                .buttonStyle(FormButtonStyle())
               
                Button { } label: {
                    Text("Selected")
                }
                .buttonStyle(FormButtonStyle(accessory: .multipleSelection(isSelected: true)))
                
                Button { } label: {
                    Text("Selected (disabled)")
                }
                .buttonStyle(FormButtonStyle(accessory: .multipleSelection(isSelected: true)))
                .disabled(true)
               
                Button { } label: {
                    Text("Unselected")
                }
                .buttonStyle(FormButtonStyle(accessory: .multipleSelection(isSelected: false)))
            }
            .compoundFormSection()

            Section {
                Button(role: .destructive) { } label: {
                    Label("Destroy", systemImage: "x.circle")
                }
                .buttonStyle(FormButtonStyle())
            }
            .compoundFormSection()
        }
    }
}
