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
    private let contentID: String?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                bgColor
                
                // This text's frame doesn't look right when redacted
                if redactionReasons != .placeholder {
                    Text(textForImage)
                        .padding(geometry.size.width <= 30 ? 0 : 4)
                        .foregroundColor(.white)
                        .font(.system(size: 200).weight(.semibold))
                        .minimumScaleFactor(0.001)
                        .frame(alignment: .center)
                }
            }
        }
        .aspectRatio(1, contentMode: .fill)
    }

    init(name: String?, contentID: String?) {
        let baseName = name ?? contentID?.trimmingCharacters(in: .punctuationCharacters)
        textForImage = baseName?.first?.uppercased() ?? ""
        self.contentID = contentID
    }

    private var bgColor: Color {
        if redactionReasons == .placeholder {
            return Color(.systemGray4) // matches the default text redaction
        }

        guard let contentID else {
            return .compound.iconPrimary
        }

        return .element.avatarBackground(for: contentID)
    }
}

struct PlaceholderAvatarImage_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 75) {
            PlaceholderAvatarImage(name: "Xavier", contentID: "@userid1:matrix.org")
                .clipShape(Circle())
                .frame(width: 150, height: 100)
            
            PlaceholderAvatarImage(name: "@*~AmazingName~*@", contentID: "@userid2:matrix.org")
                .clipShape(Circle())
                .frame(width: 150, height: 100)
            
            PlaceholderAvatarImage(name: nil, contentID: "@userid3:matrix.org")
                .clipShape(Circle())
                .frame(width: 150, height: 100)
            
            PlaceholderAvatarImage(name: nil, contentID: "@fooserid:matrix.org")
                .clipShape(Circle())
                .frame(width: 30, height: 30)
        }
    }
}
