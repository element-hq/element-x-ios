//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct ChatsSpaceFilterCell: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let filter: SpaceServiceFilter
    let mediaProvider: MediaProviderProtocol!
        
    private let verticalInsets = 12.0
    private let horizontalInsets = 16.0
    
    let action: (SpaceServiceFilter) -> Void

    var body: some View {
        Button {
            action(filter)
        } label: {
            HStack(spacing: 12.0) {
                HStack(spacing: 8.0) {
                    if filter.level > 0 {
                        Spacer(minLength: 16 * CGFloat(filter.level))
                    }
                    
                    HStack(spacing: 12.0) {
                        avatar
                        
                        content
                            .padding(.vertical, verticalInsets)
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .fill(Color.compound.borderDisabled)
                                    .frame(height: 1 / UIScreen.main.scale)
                                    .padding(.trailing, -horizontalInsets)
                            }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(.horizontal, horizontalInsets)
    }
    
    @ViewBuilder @MainActor
    private var avatar: some View {
        if dynamicTypeSize < .accessibility3 {
            RoomAvatarImage(avatar: filter.room.avatar,
                            avatarSize: .room(on: .spaceFilters),
                            mediaProvider: mediaProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
    
    private var content: some View {
        ZStack {
            // Hidden text to maintain consistent height.
            placeholderContent.hidden()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(filter.room.name)
                    .font(.compound.bodyLG)
                    .foregroundColor(.compound.textPrimary)
                    .lineLimit(1)
                
                if let alias = filter.room.canonicalAlias {
                    Text(alias)
                        .font(.compound.bodyMD)
                        .foregroundColor(.compound.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var placeholderContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(filter.room.name)
                .font(.compound.bodyLG)
                .lineLimit(1)
            
            Text(" ")
                .font(.compound.bodyMD)
                .lineLimit(1)
        }
    }
}

struct ChatsSpaceFilterCell_Previews: PreviewProvider, TestablePreview {
    static let mediaProvider = MediaProviderMock(configuration: .init())
    
    static let spaces = [SpaceServiceRoom].mockJoinedSpaces2
    
    static var previews: some View {
        VStack(spacing: 0) {
            ForEach(spaces, id: \.id) { space in
                ChatsSpaceFilterCell(filter: .init(room: space, level: 0, descendants: .init()),
                                     mediaProvider: mediaProvider) { _ in }
                ChatsSpaceFilterCell(filter: .init(room: space, level: 1, descendants: .init()),
                                     mediaProvider: mediaProvider) { _ in }
            }
        }
    }
}
