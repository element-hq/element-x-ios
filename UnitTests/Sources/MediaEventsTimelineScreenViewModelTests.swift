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
                                                           appMediator: AppMediatorMock(.init()),
                                                           appSettings: AppSettings.volatile())
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
    
    // MARK: - Helpers
    
    // Both timelines are given the same mixed chunk of items, filtered as they are in the app, so that
    // the filtering of the items is what's under test.
    private func makeTimelineViewModel(allowedGalleryItemTypes: [TimelineAllowedGalleryItemType]) -> TimelineViewModel {
        let timelineController = TimelineControllerMock(.init(timelineKind: .media(.mediaFilesScreen),
                                                              timelineItems: [TimelineFixtures.separator] + TimelineFixtures.mediaChunk,
                                                              allowedGalleryItemTypes: allowedGalleryItemTypes))
        return TimelineViewModel.mock(timelineKind: .media(.mediaFilesScreen), timelineController: timelineController)
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
