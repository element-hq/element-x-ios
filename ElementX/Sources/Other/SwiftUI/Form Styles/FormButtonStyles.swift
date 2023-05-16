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
enum FormRowAccessory: View {
    case navigationLink
    case progressView
    case selection(isSelected: Bool)
    case singleSelection(isSelected: Bool)
    
    var body: some View {
        switch self {
        case .navigationLink:
            Image(systemName: "chevron.forward")
                .font(.compound.bodyMD.bold())
                .foregroundColor(.element.quaternaryContent)
        case .progressView:
            ProgressView()
        case .selection(let isSelected):
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.compound.bodyLG)
                .foregroundColor(isSelected ? .element.primaryContent : .element.tertiaryContent)
        case .singleSelection(let isSelected):
            Image(systemName: "checkmark")
                .font(.compound.bodyLG)
                .foregroundColor(isSelected ? .element.primaryContent : .clear)
        }
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
    struct Style: ButtonStyle {
        var accessory: FormRowAccessory?
        
        func makeBody(configuration: Configuration) -> some View {
            HStack {
                configuration.label
                    .labelStyle(FormRowLabelStyle(role: configuration.role))
                    .foregroundColor(.element.primaryContent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                accessory
            }
            .contentShape(Rectangle())
            .padding(FormRow.insets) // Re-apply the normal insets using padding.
            .background(configuration.isPressed ? Color.element.quinaryContent : .clear)
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
                .foregroundColor(.element.primaryContent)
                .frame(width: menuIconSize, height: menuIconSize)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(configuration.isPressed ? Color.element.quinaryContent : .element.formRowBackground)
                }
            
            Text(title)
                .foregroundColor(.element.secondaryContent)
                .font(.compound.bodyMD)
        }
    }
}

struct FormButtonStyles_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            Section {
                Button { } label: {
                    Label("Hello world", systemImage: "globe")
                }
                .buttonStyle(FormButtonStyle())
                
                Button { } label: {
                    Label("Show something", systemImage: "rectangle.portrait")
                }
                .buttonStyle(FormButtonStyle(accessory: .navigationLink))

                Button(role: .destructive) { } label: {
                    Label("Show destruction", systemImage: "rectangle.portrait")
                }
                .buttonStyle(FormButtonStyle(accessory: .navigationLink))
                
                ShareLink(item: "test")
                    .buttonStyle(FormButtonStyle())
            }
            .formSectionStyle()
            
            Section {
                Button { } label: {
                    Text("Hello world")
                }
                .buttonStyle(FormButtonStyle())
                Button { } label: {
                    Text("Selection")
                }
                .buttonStyle(FormButtonStyle(accessory: .selection(isSelected: false)))
                Button { } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hello world")
                            Text("subtitle\nsubtitle")
                                .font(.compound.bodyMD)
                                .foregroundColor(.element.secondaryContent)
                        }
                    } icon: {
                        Image(systemName: "globe")
                    }
                }
                .buttonStyle(FormButtonStyle(iconAlignment: .top, accessory: .singleSelection(isSelected: true)))
            }
            .formSectionStyle()

            Section {
                Button(role: .destructive) { } label: {
                    Label("Destroy", systemImage: "x.circle")
                }
                .buttonStyle(FormButtonStyle())
            }
            .formSectionStyle()
        }
    }
}
