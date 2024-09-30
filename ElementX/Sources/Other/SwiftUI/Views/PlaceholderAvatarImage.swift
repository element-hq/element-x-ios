//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct PlaceholderAvatarImage: View {
    @Environment(\.redactionReasons) private var redactionReasons

    private let textForImage: String
    private let contentID: String?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                backgroundColor
                
                // This text's frame doesn't look right when redacted
                if redactionReasons != .placeholder {
                    Text(textForImage)
                        .foregroundColor(avatarColor?.text ?? .white)
                        .font(.system(size: geometry.size.width * 0.5625, weight: .semibold))
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

    private var backgroundColor: Color {
        if redactionReasons.contains(.placeholder) {
            return Color(.systemGray4) // matches the default text redaction
        }

        return avatarColor?.background ?? .compound.iconPrimary
    }
    
    private var avatarColor: DecorativeColor? {
        guard let contentID else {
            return nil
        }
        
        return Color.compound.decorativeColor(for: contentID)
    }
}

struct PlaceholderAvatarImage_Previews: PreviewProvider, TestablePreview {
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
