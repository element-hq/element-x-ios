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
    
    var body: some View {
        switch self {
        case .navigationLink:
            return Image(systemName: "chevron.forward")
                .font(.element.subheadlineBold)
                .foregroundColor(.element.quaternaryContent)
        }
    }
}

/// Default button styling for form rows.
struct FormButtonStyle: ButtonStyle {
    var accessory: FormRowAccessory?
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .labelStyle(FormRowLabelStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            accessory
        }
        .contentShape(Rectangle())
        .padding(FormConstants.rowInsets)
        .background(configuration.isPressed ? Color.element.quinaryContent : .clear)
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
                .font(.element.subheadline)
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
                .listRowInsets(EdgeInsets())
                .buttonStyle(FormButtonStyle())
                
                ShareLink(item: "test")
                    .listRowInsets(EdgeInsets())
                    .buttonStyle(FormButtonStyle())
            }
            .formSectionStyle()
        }
    }
}
