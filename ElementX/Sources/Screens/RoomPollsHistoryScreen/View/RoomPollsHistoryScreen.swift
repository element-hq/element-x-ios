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

import Compound
import SwiftUI

struct RoomPollsHistoryScreen: View {
    @Environment(\.timelineStyle) var timelineStyle
    @ObservedObject var context: RoomPollsHistoryScreenViewModel.Context
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                modePicker
                
                polls

                if !context.viewState.isInitializing {
                    if context.viewState.pollTimelineItems.isEmpty {
                        Spacer(minLength: 32)
                    }

                    if context.viewState.pollTimelineItems.isEmpty {
                        emptyStateMessage
                    }
                    
                    if context.viewState.canBackPaginate {
                        if !context.viewState.pollTimelineItems.isEmpty {
                            Spacer(minLength: 16)
                        }
                        loadMoreButton
                    }
                }
            }
            .padding()
        }
        .alert(item: $context.alertInfo)
        .scrollContentBackground(.hidden)
        .background(.compound.bgSubtleSecondaryLevel0)
        .navigationTitle(context.viewState.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Private
    
    private var modePicker: some View {
        Picker("", selection: $context.filter) {
            ForEach(context.viewState.filters, id: \.self) { filter in
                Text(filter.description)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: context.filter) { value in
            context.send(viewAction: .filter(value))
        }
    }
    
    private var polls: some View {
        ForEach(context.viewState.pollTimelineItems, id: \.item.id.eventID) { pollTimelineItem in
            VStack(alignment: .leading, spacing: 8) {
                Text(DateFormatter.pollTimestamp.string(from: pollTimelineItem.timestamp))
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textSecondary)
                PollView(poll: pollTimelineItem.item.poll, editable: pollTimelineItem.item.isEditable) { action in
                    switch action {
                    case .selectOption(let optionID):
                        guard let pollStartID = pollTimelineItem.item.id.eventID else { return }
                        context.send(viewAction: .sendPollResponse(pollStartID: pollStartID, optionID: optionID))
                    case .edit:
                        guard let pollStartID = pollTimelineItem.item.id.eventID else { return }
                        context.send(viewAction: .edit(pollStartID: pollStartID, poll: pollTimelineItem.item.poll))
                    case .end:
                        guard let pollStartID = pollTimelineItem.item.id.eventID else { return }
                        context.send(viewAction: .end(pollStartID: pollStartID))
                    }
                }
            }
            .padding(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
            .background(.compound.bgCanvasDefault)
            .cornerRadius(12, corners: .allCorners)
        }
    }
    
    private var emptyStateMessage: some View {
        Text(context.viewState.emptyStateMessage)
            .font(.compound.bodyLG)
            .foregroundColor(.compound.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.vertical, 12)
    }
    
    private var loadMoreButton: some View {
        Button {
            context.send(viewAction: .loadMore)
        } label: {
            Text(L10n.Action.loadMore)
                .font(.compound.bodyLGSemibold)
                .padding(.horizontal, 12)
        }
        .accessibilityIdentifier(A11yIdentifiers.roomPollsHistoryScreen.loadMore)
        .buttonStyle(.compound(.secondary))
        .fixedSize()
        .disabled(context.viewState.isBackPaginating)
    }
}

private extension DateFormatter {
    static let pollTimestamp: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        return dateFormatter
    }()
}

// MARK: - Previews

struct RoomPollsHistoryScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModelEmpty: RoomPollsHistoryScreenViewModel = {
        let roomPollsHistoryTimelineController = MockRoomPollsHistoryTimelineController()
        roomPollsHistoryTimelineController.backPaginationResponses = [
            [],
            []
        ]

        let viewModel = RoomPollsHistoryScreenViewModel(pollInteractionHandler: PollInteractionHandlerMock(),
                                                        roomPollsHistoryTimelineController: roomPollsHistoryTimelineController,
                                                        userIndicatorController: UserIndicatorControllerMock())
        return viewModel
    }()

    static let viewModel: RoomPollsHistoryScreenViewModel = {
        let roomPollsHistoryTimelineController = MockRoomPollsHistoryTimelineController()
        roomPollsHistoryTimelineController.backPaginationResponses = [
            [PollRoomTimelineItem.mock(poll: .emptyDisclosed, isEditable: true),
             PollRoomTimelineItem.mock(poll: .disclosed(createdByAccountOwner: true)),
             PollRoomTimelineItem.mock(poll: .disclosed(createdByAccountOwner: false))],
            []
        ]

        let viewModel = RoomPollsHistoryScreenViewModel(pollInteractionHandler: PollInteractionHandlerMock(),
                                                        roomPollsHistoryTimelineController: roomPollsHistoryTimelineController,
                                                        userIndicatorController: UserIndicatorControllerMock())
        
        return viewModel
    }()

    static var previews: some View {
        NavigationStack {
            RoomPollsHistoryScreen(context: viewModelEmpty.context)
                .environment(\.timelineStyle, .bubbles)
        }
        .previewDisplayName("No polls")
        .snapshot(delay: 1.0)

        NavigationStack {
            RoomPollsHistoryScreen(context: viewModel.context)
                .environment(\.timelineStyle, .bubbles)
        }
        .previewDisplayName("polls")
        .snapshot(delay: 1.0)
    }
}
