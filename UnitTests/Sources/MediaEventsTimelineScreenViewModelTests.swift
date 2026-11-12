//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
struct MediaEventsTimelineScreenViewModelTests {
    @Test("Changing the screen mode switches between the media and files timelines")
    func changingScreenModeSwitchesTimelines() {
        let mediaTimelineViewModel = makeTimelineViewModel(timelineController: makeTimelineController(allowedGalleryItemTypes: [.image, .video]))
        let filesTimelineViewModel = makeTimelineViewModel(timelineController: makeTimelineController(allowedGalleryItemTypes: [.file, .audio]))
        
        let viewModel = MediaEventsTimelineScreenViewModel(mediaTimelineViewModel: mediaTimelineViewModel,
                                                           filesTimelineViewModel: filesTimelineViewModel,
                                                           mediaProvider: MediaProviderMock(.init()),
                                                           userIndicatorController: UserIndicatorControllerMock(),
                                                           appMediator: AppMediatorMock(.init()))
        let context = viewModel.context
        
        // Initially the media timeline is active, showing only images and videos.
        #expect(context.viewState.screenMode == .media)
        #expect(context.viewState.activeTimelineContext === mediaTimelineViewModel.context)
        #expect(allItemsMatchScreenMode(.media, groups: context.viewState.groups))
        
        // When switching the mode, the files timeline becomes active,
        // showing only files, audio and voice messages.
        context.send(viewAction: .changeScreenMode(.files))
        
        #expect(context.viewState.screenMode == .files)
        #expect(context.viewState.activeTimelineContext === filesTimelineViewModel.context)
        #expect(allItemsMatchScreenMode(.files, groups: context.viewState.groups))
        
        // And switching back restores the media timeline.
        context.send(viewAction: .changeScreenMode(.media))
        
        #expect(context.viewState.screenMode == .media)
        #expect(context.viewState.activeTimelineContext === mediaTimelineViewModel.context)
        #expect(allItemsMatchScreenMode(.media, groups: context.viewState.groups))
    }
    
    @Test("The loading indicator stays visible until the start of the timeline is reached")
    func backPaginationIndicator() async throws {
        let timelineController = makeTimelineController(allowedGalleryItemTypes: [.image, .video])
        let mediaTimelineViewModel = makeTimelineViewModel(timelineController: timelineController)
        let filesTimelineViewModel = makeTimelineViewModel(timelineController: makeTimelineController(allowedGalleryItemTypes: [.file, .audio]))
        
        let viewModel = MediaEventsTimelineScreenViewModel(mediaTimelineViewModel: mediaTimelineViewModel,
                                                           filesTimelineViewModel: filesTimelineViewModel,
                                                           mediaProvider: MediaProviderMock(.init()),
                                                           userIndicatorController: UserIndicatorControllerMock(),
                                                           appMediator: AppMediatorMock(.init()))
        let context = viewModel.context
        
        // Given a timeline that is loading a page of older items.
        try await updateBackwardPaginationState(.paginating, of: timelineController, observedBy: mediaTimelineViewModel)
        #expect(context.viewState.canBackPaginate)
        
        // When the page has loaded but there are still older items to load.
        try await updateBackwardPaginationState(.idle, of: timelineController, observedBy: mediaTimelineViewModel)
        
        // Then the loading indicator should remain visible.
        #expect(context.viewState.canBackPaginate)
        
        // When the start of the timeline is reached.
        try await updateBackwardPaginationState(.endReached, of: timelineController, observedBy: mediaTimelineViewModel)
        
        // Then the loading indicator should be hidden.
        #expect(!context.viewState.canBackPaginate)
    }
    
    // MARK: - Helpers
    
    // Both timelines are given the same mixed chunk of items, filtered as they are in the app, so that
    // the filtering of the items is what's under test.
    private func makeTimelineController(allowedGalleryItemTypes: [TimelineAllowedGalleryItemType]) -> TimelineControllerMock {
        TimelineControllerMock(.init(timelineKind: .media(.mediaFilesScreen),
                                     timelineItems: [TimelineFixtures.separator] + TimelineFixtures.mediaChunk,
                                     allowedGalleryItemTypes: allowedGalleryItemTypes))
    }
    
    private func makeTimelineViewModel(timelineController: TimelineControllerMock) -> TimelineViewModel {
        TimelineViewModel.mock(timelineKind: .media(.mediaFilesScreen), timelineController: timelineController)
    }
    
    private func updateBackwardPaginationState(_ backward: PaginationState,
                                               of timelineController: TimelineControllerMock,
                                               observedBy timelineViewModel: TimelineViewModel) async throws {
        let deferred = deferFulfillment(timelineViewModel.context.$viewState) { $0.timelineState.paginationState.backward == backward }
        timelineController.update(paginationState: .init(backward: backward, forward: .endReached))
        try await deferred.fulfill()
    }
    
    private func allItemsMatchScreenMode(_ screenMode: MediaEventsTimelineScreenMode, groups: [MediaEventsTimelineGroup]) -> Bool {
        let items = groups.flatMap(\.items)
        guard !items.isEmpty else { return false }
        
        return items.allSatisfy { item in
            switch item.type {
            case .image, .video: screenMode == .media
            case .audio, .file, .voice: screenMode == .files
            default: false
            }
        }
    }
}
