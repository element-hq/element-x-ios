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

struct PlaceholderAvatarImage: View {
    private let textForImage: String
    
    var body: some View {
        ZStack {
            Color.element.accent
            Text(textForImage)
                .padding(4)
                .foregroundColor(.element.systemGray3)
                // Make the text resizable (i.e. Make it large and then allow it to scale down)
                .font(.system(size: 200).weight(.semibold))
                .minimumScaleFactor(0.001)
        }
        .aspectRatio(1, contentMode: .fill)
    }

    init(text: String) {
        textForImage = text.first?.uppercased() ?? ""
    }
}

struct PlaceholderAvatarImage_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        PlaceholderAvatarImage(text: "X")
            .clipShape(Circle())
            .frame(width: 150, height: 100)
    }
}
