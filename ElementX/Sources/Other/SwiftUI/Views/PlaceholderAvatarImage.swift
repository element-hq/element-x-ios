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
    @Environment(\.redactionReasons) var redactionReasons

    private let textForImage: String
    private let contentId: String?
    
    var body: some View {
        ZStack {
            bgColor
            
            // This text's frame doesn't look right when redacted
            if redactionReasons != .placeholder {
                Text(textForImage)
                    .padding(4)
                    .foregroundColor(.white)
                    .font(.system(size: 200).weight(.semibold))
                    .minimumScaleFactor(0.001)
            }
        }
        .aspectRatio(1, contentMode: .fill)
    }

    init(text: String, contentId: String? = nil) {
        textForImage = text.first?.uppercased() ?? ""
        self.contentId = contentId
    }

    private var bgColor: Color {
        if redactionReasons == .placeholder {
            return .element.systemGray4
        }
        
        guard let contentId else {
            return .element.accent
        }

        return .element.avatarBackground(for: contentId)
    }
}

struct PlaceholderAvatarImage_Previews: PreviewProvider {
    static var previews: some View {
        PlaceholderAvatarImage(text: "X", contentId: "@userid:matrix.org")
            .clipShape(Circle())
            .frame(width: 150, height: 100)
    }
}
