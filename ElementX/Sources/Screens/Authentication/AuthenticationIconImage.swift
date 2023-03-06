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

/// An image that is styled for use as the screen icon in the onboarding flow.
struct AuthenticationIconImage: View {
    /// The icon that is shown.
    let image: Image
    /// The amount of padding between the icon and the borders. Defaults to 16.
    var insets: CGFloat = 16
    
    var body: some View {
        image
            .resizable()
            .renderingMode(.template)
            .foregroundColor(.element.secondaryContent)
            .aspectRatio(contentMode: .fit)
            .accessibilityHidden(true)
            .padding(insets)
            .frame(width: 70, height: 70)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.element.quinaryContent)
            }
    }
}

// MARK: - Previews

struct AuthenticationIconImage_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            AuthenticationIconImage(image: Image(asset: Asset.Images.serverSelectionIcon), insets: 19)
            AuthenticationIconImage(image: Image(systemName: "hourglass"))
        }
    }
}
