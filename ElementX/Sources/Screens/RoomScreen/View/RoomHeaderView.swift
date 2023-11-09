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

import Combine
import Foundation
import SwiftUI

struct RoomHeaderView: View {
    @ObservedObject var context: RoomScreenViewModel.Context

    var body: some View {
        HStack(spacing: 12) {
            roomAvatar
                .accessibilityHidden(true)
            Text(context.viewState.roomTitle)
                .font(.compound.bodyLGSemibold)
                .accessibilityIdentifier(A11yIdentifiers.roomScreen.name)
        }
        // Leading align whilst using the principal toolbar position.
        .frame(maxWidth: .infinity, alignment: .leading)
        // Using a button stops is from getting truncated in the navigation bar
        .onTapGesture {
            context.send(viewAction: .displayRoomDetails)
        }
    }

    @ViewBuilder private var roomAvatar: some View {
        LoadableAvatarImage(url: context.viewState.roomAvatarURL,
                            name: context.viewState.roomTitle,
                            contentID: context.viewState.roomID,
                            avatarSize: .room(on: .timeline),
                            imageProvider: context.imageProvider)
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.avatar)
    }
}

struct RoomHeaderView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        bodyPlain
        bodyEncrypted
    }

    @ViewBuilder
    static var bodyPlain: some View {
        let viewModel = RoomScreenViewModel(roomProxy: RoomProxyMock(with: .init(displayName: "Some Room name", avatarURL: URL.picturesDirectory)),
                                            timelineController: MockRoomTimelineController(),
                                            mediaProvider: MockMediaProvider(),
                                            mediaPlayerProvider: MediaPlayerProviderMock(),
                                            voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                            userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                            application: ApplicationMock.default,
                                            appSettings: ServiceLocator.shared.settings,
                                            analyticsService: ServiceLocator.shared.analytics,
                                            notificationCenter: NotificationCenterMock())

        RoomHeaderView(context: viewModel.context)
            .previewLayout(.sizeThatFits)
            .padding()
    }
    
    @ViewBuilder
    static var bodyEncrypted: some View {
        let viewModel = RoomScreenViewModel(roomProxy: RoomProxyMock(with: .init(displayName: "Some Room name")),
                                            timelineController: MockRoomTimelineController(),
                                            mediaProvider: MockMediaProvider(),
                                            mediaPlayerProvider: MediaPlayerProviderMock(),
                                            voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                            userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                            application: ApplicationMock.default,
                                            appSettings: ServiceLocator.shared.settings,
                                            analyticsService: ServiceLocator.shared.analytics,
                                            notificationCenter: NotificationCenterMock())

        RoomHeaderView(context: viewModel.context)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
