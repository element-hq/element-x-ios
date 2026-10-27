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
    @Test
    func changingScreenModeSwitchesTimelines() {
        let mediaTimelineViewModel = makeTimelineViewModel(allowedGalleryItemTypes: [.image, .video])
        let filesTimelineViewModel = makeTimelineViewModel(allowedGalleryItemTypes: [.file, .audio])
        
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
    
    @Test
    func backPaginationIndicatorStaysVisibleBetweenRequests() async throws {
        let mediaTimelineController = makeTimelineController(allowedGalleryItemTypes: [.image, .video])
        let viewModel = MediaEventsTimelineScreenViewModel(mediaTimelineViewModel: TimelineViewModel.mock(timelineKind: .media(.mediaFilesScreen),
                                                                                                          timelineController: mediaTimelineController),
                                                           filesTimelineViewModel: makeTimelineViewModel(allowedGalleryItemTypes: [.file, .audio]),
                                                           mediaProvider: MediaProviderMock(.init()),
                                                           userIndicatorController: UserIndicatorControllerMock(),
                                                           appMediator: AppMediatorMock(.init()))
        let context = viewModel.context
        
        var deferred = deferFulfillment(context.observe(\.viewState.isBackPaginating)) { $0 }
        mediaTimelineController.update(paginationState: .init(backward: .paginating, forward: .endReached))
        try await deferred.fulfill()
        
        // The idle gap before the next request in the chain shouldn't hide the indicator.
        let deferredFailure = deferFailure(context.observe(\.viewState.isBackPaginating), timeout: .seconds(1)) { !$0 }
        mediaTimelineController.update(paginationState: .init(backward: .idle, forward: .endReached))
        mediaTimelineController.update(paginationState: .init(backward: .paginating, forward: .endReached))
        try await deferredFailure.fulfill()
        
        // But once the requests stop (e.g. after a failure), the indicator is hidden.
        deferred = deferFulfillment(context.observe(\.viewState.isBackPaginating)) { !$0 }
        mediaTimelineController.update(paginationState: .init(backward: .idle, forward: .endReached))
        try await deferred.fulfill()
    }
    
    // MARK: - Helpers
    
    // Both timelines are given the same mixed chunk of items, filtered as they are in the app, so that
    // the filtering of the items is what's under test.
    private func makeTimelineViewModel(allowedGalleryItemTypes: [TimelineAllowedGalleryItemType]) -> TimelineViewModel {
        TimelineViewModel.mock(timelineKind: .media(.mediaFilesScreen),
                               timelineController: makeTimelineController(allowedGalleryItemTypes: allowedGalleryItemTypes))
    }
    
    private func makeTimelineController(allowedGalleryItemTypes: [TimelineAllowedGalleryItemType]) -> TimelineControllerMock {
        TimelineControllerMock(.init(timelineKind: .media(.mediaFilesScreen),
                                     timelineItems: [TimelineFixtures.separator] + TimelineFixtures.mediaChunk,
                                     allowedGalleryItemTypes: allowedGalleryItemTypes))
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
