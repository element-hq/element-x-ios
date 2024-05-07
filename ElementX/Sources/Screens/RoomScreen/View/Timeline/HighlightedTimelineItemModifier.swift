//
// Copyright 2024 New Vector Ltd
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

import Compound
import SwiftUI

extension View {
    func highlightedTimelineItem(_ isHighlighted: Bool) -> some View {
        modifier(HighlightedTimelineItemModifier(isHighlighted: isHighlighted))
    }
}

private struct HighlightedTimelineItemModifier: ViewModifier {
    let isHighlighted: Bool
    
    func body(content: Content) -> some View {
        content
            .padding(.top, isHighlighted ? 1 : 0)
            .background {
                if isHighlighted {
                    VStack(spacing: 0) {
                        Color.compound._bgBubbleHighlighted
                        LinearGradient(colors: [.compound._bgBubbleHighlighted, .clear],
                                       startPoint: .top,
                                       endPoint: .bottom)
                            .frame(maxHeight: 200)
                            .layoutPriority(1)
                    }
                    .overlay(alignment: .top) {
                        Color.compound.bgAccentRest
                            .frame(height: 1)
                    }
                }
            }
    }
}

// MARK: - Previews

// swiftlint:disable line_length blanket_disable_command
struct HighlightedTimelineItemModifier_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                Bubble(text: "Hello 👋")
                    .highlightedTimelineItem(true)
                
                Bubble(text: "Not highlighted")
                    .highlightedTimelineItem(false)
                
                // swiftlint:disable line_length
                Bubble(text: """
                       Bacon ipsum dolor amet brisket bacon hamburger filet mignon ham hock, capicola meatloaf corned beef tongue. Ribeye filet mignon shoulder drumstick doner shank. Landjaeger shankle chislic brisket short loin pig. Frankfurter sirloin jerky bresaola tri-tip cow buffalo. Beef tongue shankle venison, sirloin boudin biltong ham hock corned beef. Sirloin shankle pork belly, strip steak pancetta brisket flank ribeye cow chislic. Pork ham landjaeger, pastrami beef sausage capicola meatball.
                       
                       Cow brisket bresaola, burgdoggen cupim turducken sirloin andouille shankle sausage jerky chicken pig. Tail capicola landjaeger frankfurter. Kevin pancetta brisket spare ribs, sausage chuck tail pork. Ground round boudin chuck tri-tip corned beef. Pork belly ham bresaola tail, pork chop meatloaf biltong filet mignon strip steak ribeye boudin shoulder frankfurter.
                       """,
                       isOutgoing: true)
                    .highlightedTimelineItem(true)
                // swiftlint:enable line_length
            }
        }
        .previewDisplayName("Layout")
    }
    
    struct Bubble: View {
        let text: String
        var isOutgoing = false
        
        var body: some View {
            Text(text)
                .padding(10)
                .background(isOutgoing ? .compound._bgBubbleOutgoing : .compound._bgBubbleIncoming,
                            in: RoundedRectangle(cornerRadius: 12))
                .padding(isOutgoing ? .leading : .trailing, 40)
                .frame(maxWidth: .infinity, alignment: isOutgoing ? .trailing : .leading)
                .padding(12)
        }
    }
}

/// A preview that allows quick testing of the highlight appearance across various timeline scenarios.
struct HighlightedTimelineItemTimeline_Previews: PreviewProvider {
    static let focussedEventID = "RoomTimelineItemFixtures.default.5"
    static let viewModel = RoomScreenViewModel(roomProxy: RoomProxyMock(with: .init(name: "Preview room")),
                                               focussedEventID: focussedEventID,
                                               timelineController: MockRoomTimelineController(),
                                               mediaProvider: MockMediaProvider(),
                                               mediaPlayerProvider: MediaPlayerProviderMock(),
                                               voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings,
                                               analyticsService: ServiceLocator.shared.analytics,
                                               notificationCenter: NotificationCenterMock())

    static var previews: some View {
        NavigationStack {
            RoomScreen(context: viewModel.context, composerToolbar: ComposerToolbar.mock())
        }
        .previewDisplayName("Timeline")
    }
}
