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
    
    let image: ImageAsset
    
    var body: some View {
        Image(image.name)
            .resizable()
            .renderingMode(.template)
            .foregroundColor(.element.accent)
            .frame(width: 90, height: 90)
            .background(.white, in: Circle().inset(by: 2))
            .accessibilityHidden(true)
    }
}

// MARK: - Previews

struct AuthenticationIconImage_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationIconImage(image: Asset.Images.serverSelectionIcon)
    }
}
