//
// Copyright 2022 New Vector Ltd
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

extension View {
    /// Applies a standard style to forms.
    func elementFormStyle() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.element.formBackground.ignoresSafeArea())
    }
    
    /// Applies a standard style for form header text.
    func formSectionHeader() -> some View {
        foregroundColor(.compound.textSecondary)
            .font(.compound.bodyXS)
    }
    
    /// Applies a standard style for form sections.
    func formSectionStyle() -> some View {
        listRowSeparator(.hidden)
            .listRowInsets(FormRow.insets)
            .listRowBackground(Color.element.formRowBackground)
    }
}
