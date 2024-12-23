//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class MediaUploadPreviewScreenViewModelTests: XCTestCase {
    var timelineProxy: TimelineProxyMock!
    var viewModel: MediaUploadPreviewScreenViewModel!
    var context: MediaUploadPreviewScreenViewModel.Context { viewModel.context }
    
    enum TestError: Swift.Error {
        case unexpectedParameter
        case unknown
    }
    
    override func setUp() {
        AppSettings.resetAllSettings()
        let appSettings = AppSettings()
        appSettings.optimizeMediaUploads = false
        ServiceLocator.shared.register(appSettings: appSettings)
    }
    
    deinit {
        AppSettings.resetAllSettings()
    }
    
    func testImageUploadWithoutCaption() async throws {
        setUpViewModel(url: imageURL, expectedCaption: nil)
        context.caption = .init("")
        try await send()
    }
    
    func testImageUploadWithBlankCaption() async throws {
        setUpViewModel(url: imageURL, expectedCaption: nil)
        context.caption = .init("     ")
        try await send()
    }
    
    func testImageUploadWithCaption() async throws {
        let caption = "This is a really great image!"
        setUpViewModel(url: imageURL, expectedCaption: caption)
        context.caption = .init(string: caption)
        try await send()
    }
    
    func testVideoUploadWithoutCaption() async throws {
        setUpViewModel(url: videoURL, expectedCaption: nil)
        context.caption = .init("")
        try await send()
    }
    
    func testVideoUploadWithCaption() async throws {
        let caption = "Check out this video!"
        setUpViewModel(url: videoURL, expectedCaption: caption)
        context.caption = .init(string: caption)
        try await send()
    }
    
    func testAudioUploadWithoutCaption() async throws {
        setUpViewModel(url: audioURL, expectedCaption: nil)
        context.caption = .init("")
        try await send()
    }
    
    func testAudioUploadWithCaption() async throws {
        let caption = "Listen to this!"
        setUpViewModel(url: audioURL, expectedCaption: caption)
        context.caption = .init(string: caption)
        try await send()
    }
    
    func testFileUploadWithoutCaption() async throws {
        setUpViewModel(url: fileURL, expectedCaption: nil)
        context.caption = .init("")
        try await send()
    }
    
    func testFileUploadWithCaption() async throws {
        let caption = "Please will you check my article."
        setUpViewModel(url: fileURL, expectedCaption: caption)
        context.caption = .init(string: caption)
        try await send()
    }
    
    // MARK: - Helpers
    
    private var audioURL: URL { assertResourceURL(filename: "test_audio.mp3") }
    private var fileURL: URL { assertResourceURL(filename: "test_pdf.pdf") }
    private var imageURL: URL { assertResourceURL(filename: "test_animated_image.gif") }
    private var videoURL: URL { assertResourceURL(filename: "landscape_test_video.mov") }
    
    private func assertResourceURL(filename: String) -> URL {
        guard let url = Bundle(for: Self.self).url(forResource: filename, withExtension: nil) else {
            XCTFail("Failed retrieving test asset")
            return .picturesDirectory
        }
        return url
    }
    
    private func setUpViewModel(url: URL, expectedCaption: String?) {
        timelineProxy = TimelineProxyMock(.init())
        timelineProxy.sendAudioUrlAudioInfoCaptionRequestHandleClosure = { [weak self] _, _, caption, _ in
            self?.verifyCaption(caption, expectedCaption: expectedCaption) ?? .failure(.sdkError(TestError.unknown))
        }
        timelineProxy.sendFileUrlFileInfoCaptionRequestHandleClosure = { [weak self] _, _, caption, _ in
            self?.verifyCaption(caption, expectedCaption: expectedCaption) ?? .failure(.sdkError(TestError.unknown))
        }
        timelineProxy.sendImageUrlThumbnailURLImageInfoCaptionRequestHandleClosure = { [weak self] _, _, _, caption, _ in
            self?.verifyCaption(caption, expectedCaption: expectedCaption) ?? .failure(.sdkError(TestError.unknown))
        }
        timelineProxy.sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleClosure = { [weak self] _, _, _, caption, _ in
            self?.verifyCaption(caption, expectedCaption: expectedCaption) ?? .failure(.sdkError(TestError.unknown))
        }
        
        let roomProxy = JoinedRoomProxyMock(.init())
        roomProxy.timeline = timelineProxy
        viewModel = MediaUploadPreviewScreenViewModel(userIndicatorController: UserIndicatorControllerMock(),
                                                      roomProxy: roomProxy,
                                                      mediaUploadingPreprocessor: MediaUploadingPreprocessor(appSettings: ServiceLocator.shared.settings),
                                                      title: "Some File",
                                                      url: url,
                                                      shouldShowCaptionWarning: true)
    }
    
    private func verifyCaption(_ caption: String?, expectedCaption: String?) -> Result<Void, TimelineProxyError> {
        guard caption == expectedCaption else {
            XCTFail("The sent caption '\(caption ?? "nil")' does not match the expected value '\(expectedCaption ?? "nil")'").self
            return .failure(.sdkError(TestError.unexpectedParameter))
        }
        return .success(())
    }
    
    private func send() async throws {
        XCTAssertFalse(context.viewState.shouldDisableInteraction, "Attempting to send when interaction is disabled.")
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.send(viewAction: .send)
        
        XCTAssertTrue(context.viewState.shouldDisableInteraction, "The interaction should be disabled while sending.")
        
        try await deferred.fulfill()
    }
}
