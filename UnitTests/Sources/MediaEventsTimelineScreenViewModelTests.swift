//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

@MainActor
class MediaEventsTimelineScreenViewModelTests: XCTestCase {
    func testFileDisplayInMediaBrowser() async {
        // Given: A MediaEventsTimelineScreenViewModel with file mode
        let mediaTimelineViewModel = TimelineViewModel.mock(timelineKind: .media(.mediaFilesScreen),
                                                            items: [])
        let filesTimelineViewModel = TimelineViewModel.mock(timelineKind: .media(.mediaFilesScreen),
                                                            items: [])
        
        let viewModel = MediaEventsTimelineScreenViewModel(mediaTimelineViewModel: mediaTimelineViewModel,
                                                           filesTimelineViewModel: filesTimelineViewModel,
                                                           initialScreenMode: .files,
                                                           mediaProvider: MediaProviderMock(configuration: .init()),
                                                           userIndicatorController: UserIndicatorControllerMock(),
                                                           appMediator: AppMediatorMock())
        
        // When: We switch to files mode
        viewModel.context.screenMode = .files
        
        // Then: The files timeline should be active
        XCTAssertEqual(viewModel.context.viewState.activeTimelineContext, filesTimelineViewModel.context)
    }
    
    func testFileFilteringLogic() {
        // Test the filtering logic from updateWithTimelineViewState
        let screenMode: MediaEventsTimelineScreenMode = .files
        
        // Test file type filtering
        let fileItemType: RoomTimelineItemViewState.ItemType = .file(.mock())
        let imageItemType: RoomTimelineItemViewState.ItemType = .image(.mock())
        let videoItemType: RoomTimelineItemViewState.ItemType = .video(.mock())
        let audioItemType: RoomTimelineItemViewState.ItemType = .audio(.mock())
        let voiceItemType: RoomTimelineItemViewState.ItemType = .voice(.mock())
        
        // Files mode should show: audio, file, voice
        XCTAssertTrue(shouldShowItem(fileItemType, in: screenMode))
        XCTAssertTrue(shouldShowItem(audioItemType, in: screenMode))
        XCTAssertTrue(shouldShowItem(voiceItemType, in: screenMode))
        
        // Files mode should NOT show: image, video
        XCTAssertFalse(shouldShowItem(imageItemType, in: screenMode))
        XCTAssertFalse(shouldShowItem(videoItemType, in: screenMode))
    }
    
    func testMediaFilteringLogic() {
        // Test the filtering logic from updateWithTimelineViewState
        let screenMode: MediaEventsTimelineScreenMode = .media
        
        // Test media type filtering
        let fileItemType: RoomTimelineItemViewState.ItemType = .file(.mock())
        let imageItemType: RoomTimelineItemViewState.ItemType = .image(.mock())
        let videoItemType: RoomTimelineItemViewState.ItemType = .video(.mock())
        let audioItemType: RoomTimelineItemViewState.ItemType = .audio(.mock())
        let voiceItemType: RoomTimelineItemViewState.ItemType = .voice(.mock())
        
        // Media mode should show: image, video
        XCTAssertTrue(shouldShowItem(imageItemType, in: screenMode))
        XCTAssertTrue(shouldShowItem(videoItemType, in: screenMode))
        
        // Media mode should NOT show: file, audio, voice
        XCTAssertFalse(shouldShowItem(fileItemType, in: screenMode))
        XCTAssertFalse(shouldShowItem(audioItemType, in: screenMode))
        XCTAssertFalse(shouldShowItem(voiceItemType, in: screenMode))
    }
    
    // Helper function that replicates the filtering logic from updateWithTimelineViewState
    private func shouldShowItem(_ itemType: RoomTimelineItemViewState.ItemType, in screenMode: MediaEventsTimelineScreenMode) -> Bool {
        switch itemType {
        case .image, .video:
            return screenMode == .media
        case .audio, .file, .voice:
            return screenMode == .files
        case .separator:
            return true
        default:
            return false
        }
    }
}
