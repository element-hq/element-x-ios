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

import Compound
import SwiftUI

/// Small squared action button style for settings screens
struct FormActionButtonStyle: ButtonStyle {
    let title: String
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 4) {
            configuration.label
                .buttonStyle(.plain)
                .foregroundColor(.compound.iconSecondary)
                .scaledFrame(size: 24)
            
            Text(title)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.bodyLG)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(configuration.isPressed ? Color.compound.bgSubtlePrimary : .compound.bgCanvasDefaultLevel1)
        }
    }
}

struct FormButtonStyles_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        Form {
            Section { } header: {
                Button { } label: {
                    CompoundIcon(\.shareIos)
                }
                .buttonStyle(FormActionButtonStyle(title: "Share"))
            }
        }
        .compoundList()
    }
}
