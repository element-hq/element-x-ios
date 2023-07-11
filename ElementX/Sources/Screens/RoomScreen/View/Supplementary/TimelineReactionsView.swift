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

import Flow
import SwiftUI

struct TimelineReactionsView: View {
    /// We use a coordinate space for measuring the reactions within their container.
    /// For some reason when using .local the origin of reactions always shown as (0, 0)
    private static let flowCoordinateSpace = "flowCoordinateSpace"
    private static let hSpacing: CGFloat = 4
    private static let vSpacing: CGFloat = 4
    
    @Environment(\.layoutDirection) private var layoutDirection: LayoutDirection
    @EnvironmentObject private var context: RoomScreenViewModel.Context

    let itemID: String
    let reactions: [AggregatedReaction]
    @Binding var collapsed: Bool
    
    @State private var collapseButtonFrame: CGRect = .zero
    @State private var reactionsContainerFame: CGRect = .zero
    @State private var reactionButtonFrames: [String: CGRect] = [:]
    
    /// The count of reactions hidden in the collapsed state
    var hiddenCount: Int {
//        reactionButtonFrames.values.map {
//            /// The reaction views minimum heigh doesn't go to zero due to padding, hence the weird number here.
//            $0.height < 20 ? 1 : 0
//        }.reduce(0, +)
        0
    }
    
    var body: some View {
        CollapsibleReactionLayout(itemSpacing: 4, rowSpacing: 4, collapsed: collapsed, rowsBeforeCollapsible: 2) {
            ForEach(reactions, id: \.self) { reaction in
                TimelineReactionButton(itemID: itemID, reaction: reaction)
                    .opacity((reactionButtonFrames[reaction.key] ?? .zero).size.height < 20 ? 0 : 1)
                    .background(ViewFrameReader(frame: reactionsFrameBinding(for: reaction.key), coordinateSpace: .named(Self.flowCoordinateSpace)))
            }
            Button {
                collapsed.toggle()
            } label: {
                TimelineCollapseButton(collapsed: collapsed, hiddenCount: hiddenCount)
            }
            /// The reaction views minimum heigh doesn't go to zero due to padding, hence the weird number here.
            .opacity(collapseButtonFrame.size.height < 20 ? 0 : 1)
            .background(ViewFrameReader(frame: $collapseButtonFrame, coordinateSpace: .named(Self.flowCoordinateSpace)))
            Button {
                context.send(viewAction: .displayEmojiPicker(itemID: itemID))
            } label: {
                TimelineReactionAddMoreButton()
            }
        }
        .background(ViewFrameReader(frame: $reactionsContainerFame, coordinateSpace: .named(Self.flowCoordinateSpace)))
        .coordinateSpace(name: Self.flowCoordinateSpace)
    }
    
    private func reactionsFrameBinding(for key: String) -> Binding<CGRect> {
        Binding(get: {
            reactionButtonFrames[key] ?? .zero
        }, set: {
            reactionButtonFrames[key] = $0
        })
    }
}

/// The pill shape for the label that surrounds both the reaction and collapse buttons.
struct TimelineReactionButtonLabel<Content: View>: View {
    var isHighlighted = false
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        content()
            .background(backgroundShape.inset(by: 1).fill(overlayBackgroundColor))
            .overlay(backgroundShape.inset(by: 2.0).strokeBorder(overlayBorderColor))
            .overlay(backgroundShape.strokeBorder(Color.compound.bgCanvasDefault, lineWidth: 2))
            .accessibilityElement(children: .combine)
    }
    
    var backgroundShape: some InsettableShape {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
    }
    
    var overlayBackgroundColor: Color {
        isHighlighted ? Color.compound.bgSubtlePrimary : .compound.bgSubtleSecondary
    }
    
    var overlayBorderColor: Color {
        isHighlighted ? Color.compound.borderInteractivePrimary : .clear
    }
}

struct TimelineCollapseButton: View {
    var collapsed: Bool
    var hiddenCount: Int
    
    var body: some View {
        TimelineReactionButtonLabel {
            Text(collapsed ? L10n.screenRoomReactionsShowMore(hiddenCount) : L10n.screenRoomReactionsShowLess)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .layoutPriority(1)
                .drawingGroup()
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
        }
    }
}

struct TimelineReactionButton: View {
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    let itemID: String
    let reaction: AggregatedReaction
    
    var body: some View {
        label
            .onTapGesture {
                context.send(viewAction: .toggleReaction(key: reaction.key, eventID: itemID))
            }
            .longPressWithFeedback {
                context.send(viewAction: .reactionSummary(itemID: itemID, key: reaction.key))
            }
    }
    
    var label: some View {
        TimelineReactionButtonLabel(isHighlighted: reaction.isHighlighted) {
            HStack(spacing: 4) {
                Text(reaction.key)
                    .font(.compound.bodyMD)
                if reaction.count > 1 {
                    Text(String(reaction.count))
                        .font(.compound.bodyMD)
                        .foregroundColor(textColor)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
        }
    }
    
    var textColor: Color {
        reaction.isHighlighted ? Color.compound.textPrimary : .compound.textSecondary
    }
}

struct TimelineReactionAddMoreButton: View {
    @ScaledMetric private var addMoreButtonIconSize = 16
    
    var body: some View {
        TimelineReactionButtonLabel {
            Image(asset: Asset.Images.timelineReactionAddMore)
                .resizable()
                .frame(width: addMoreButtonIconSize, height: addMoreButtonIconSize)
                // Vertical sizing is done by the layout so that the add more button
                // matches the height of the text based buttons.
                .padding(.horizontal, 8)
                .frame(maxHeight: .infinity, alignment: .center)
        }
    }
}

struct TimelineReactionViewPreviewsContainer: View {
    @State private var collapseState1 = false
    @State private var collapseState2 = true

    var body: some View {
        VStack {
//            TimelineReactionsView(itemID: "1", reactions: Array(AggregatedReaction.mockReactions.prefix(3)), collapsed: .constant(true))
//            Divider()
            TimelineReactionsView(itemID: "2", reactions: AggregatedReaction.mockReactions2, collapsed: $collapseState1)
//            Divider()
//            TimelineReactionsView(itemID: "3", reactions: AggregatedReaction.mockReactions, collapsed: $collapseState2)
//                .environment(\.layoutDirection, .rightToLeft)
        }
        .background(Color.red)
        .frame(maxWidth: 250, alignment: .leading)
    }
}

struct TimelineReactionView_Previews: PreviewProvider {
    static var previews: some View {
        TimelineReactionViewPreviewsContainer()
    }
}
