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

import Compound

struct ThreadDecorator: View {
    var body: some View {
        Label {
            Text(L10n.commonThread)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.bodyXS)
        } icon: {
            CompoundIcon(\.threads, size: .custom(16), relativeTo: .compound.bodyXS)
                .foregroundColor(.compound.iconSecondary)
        }
        .labelStyle(.custom(spacing: 4))
    }
}

struct ThreadDecorator_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        ThreadDecorator()
    }
}
