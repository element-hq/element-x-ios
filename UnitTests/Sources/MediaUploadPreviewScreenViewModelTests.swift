//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor @Suite
struct MediaUploadPreviewScreenViewModelTests {
    var timelineProxy: TimelineProxyMock!
    var clientProxy: ClientProxyMock!
    var userIndicatorController: UserIndicatorControllerMock!
    
    var viewModel: MediaUploadPreviewScreenViewModel!
    var context: MediaUploadPreviewScreenViewModel.Context {
        viewModel.context
    }
    
    enum TestError: Swift.Error {
        case unexpectedParameter
        case unknown
    }
    
    init() {
        AppSettings.resetAllSettings()
        let appSettings = AppSettings()
        appSettings.optimizeMediaUploads = false
        ServiceLocator.shared.register(appSettings: appSettings)
    }
    
    @Test
    mutating func imageUploadWithoutCaption() async throws {
        setUpViewModel(urls: [imageURL], expectedCaption: nil)
        context.caption = .init("")
        try await send()
    }
    
    @Test
    mutating func imageUploadWithBlankCaption() async throws {
        setUpViewModel(urls: [imageURL], expectedCaption: nil)
        context.caption = .init("     ")
        try await send()
    }
    
    @Test
    mutating func imageUploadWithCaption() async throws {
        let caption = "This is a really great image!"
        setUpViewModel(urls: [imageURL], expectedCaption: caption)
        context.caption = .init(string: caption)
        try await send()
    }
    
    @Test
    mutating func videoUploadWithoutCaption() async throws {
        setUpViewModel(urls: [videoURL], expectedCaption: nil)
        context.caption = .init("")
        try await send()
    }
    
    @Test
    mutating func videoUploadWithCaption() async throws {
        let caption = "Check out this video!"
        setUpViewModel(urls: [videoURL], expectedCaption: caption)
        context.caption = .init(string: caption)
        try await send()
    }
    
    @Test
    mutating func audioUploadWithoutCaption() async throws {
        setUpViewModel(urls: [audioURL], expectedCaption: nil)
        context.caption = .init("")
        try await send()
    }
    
    @Test
    mutating func audioUploadWithCaption() async throws {
        let caption = "Listen to this!"
        setUpViewModel(urls: [audioURL], expectedCaption: caption)
        context.caption = .init(string: caption)
        try await send()
    }
    
    @Test
    mutating func fileUploadWithoutCaption() async throws {
        setUpViewModel(urls: [fileURL], expectedCaption: nil)
        context.caption = .init("")
        try await send()
    }
    
    @Test
    mutating func fileUploadWithCaption() async throws {
        let caption = "Please will you check my article."
        setUpViewModel(urls: [fileURL], expectedCaption: caption)
        context.caption = .init(string: caption)
        try await send()
    }
    
    @Test
    mutating func processingFailure() async throws {
        // Given an upload screen for a non-existent file.
        setUpViewModel(urls: [badImageURL], expectedCaption: nil)
        #expect(!context.viewState.shouldDisableInteraction)
        #expect(userIndicatorController.submitIndicatorDelayCallsCount == 0)
        
        // When attempting to send the file
        let deferredFailure = deferFailure(viewModel.actions, timeout: 1, message: "The screen should remain visible.") { $0 == .dismiss }
        context.send(viewAction: .send)
        #expect(context.viewState.shouldDisableInteraction, "The interaction should be disabled while sending.")
        #expect(userIndicatorController.submitIndicatorDelayCallsCount == 1) // Loading indicator
        
        // Then the failure should occur preventing the screen from being dismissed.
        try await deferredFailure.fulfill()
        #expect(!context.viewState.shouldDisableInteraction)
        #expect(userIndicatorController.submitIndicatorDelayCallsCount == 2, "An error indicator should be shown.")
    }
    
    @Test
    mutating func uploadWithUnknownMaxUploadSize() async throws {
        // Given an upload screen that is unable to fetch the max upload size.
        setUpViewModel(urls: [imageURL], expectedCaption: nil, maxUploadSizeResult: .failure(.sdkError(ClientProxyMockError.generic)))
        #expect(!context.viewState.shouldDisableInteraction)
        #expect(context.alertInfo == nil)
        
        // When attempting to send the media.
        let deferredAlert = deferFulfillment(context.observe(\.viewState.bindings.alertInfo)) { $0 != nil }
        let deferredFailure = deferFailure(viewModel.actions, timeout: 1, message: "The screen should remain visible.") { $0 == .dismiss }
        context.send(viewAction: .send)
        
        #expect(context.viewState.shouldDisableInteraction, "The interaction should be disabled while sending.")
        
        // Then alert should be shown to tell the user it failed.
        try await deferredAlert.fulfill()
        try await deferredFailure.fulfill()
        
        #expect(!context.viewState.shouldDisableInteraction)
        #expect(context.alertInfo?.id == .maxUploadSizeUnknown)
        
        // When trying with the max upload size now available.
        let deferredDismiss = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        clientProxy.underlyingMaxMediaUploadSize = .success(100 * 1024 * 1024)
        context.alertInfo?.primaryButton.action?()
        
        #expect(context.viewState.shouldDisableInteraction, "The interaction should be disabled while retrying.")
        
        // Then the file should upload successfully.
        try await deferredDismiss.fulfill()
    }
    
    @Test
    mutating func uploadExceedingMaxUploadSize() async throws {
        // Given an upload screen with a really small max upload size.
        setUpViewModel(urls: [imageURL], expectedCaption: nil, maxUploadSizeResult: .success(100))
        #expect(!context.viewState.shouldDisableInteraction)
        #expect(context.alertInfo == nil)
        
        // When attempting to send an image that is larger the limit.
        let deferredAlert = deferFulfillment(context.observe(\.viewState.bindings.alertInfo)) { $0 != nil }
        let deferredFailure = deferFailure(viewModel.actions, timeout: 1, message: "The screen should remain visible.") { $0 == .dismiss }
        context.send(viewAction: .send)
        
        #expect(context.viewState.shouldDisableInteraction, "The interaction should be disabled while sending.")
        
        // Then an alert should be shown to inform the user of the max upload size.
        try await deferredAlert.fulfill()
        try await deferredFailure.fulfill()
        
        #expect(!context.viewState.shouldDisableInteraction)
        #expect(context.alertInfo?.id == .maxUploadSizeExceeded(limit: 100))
    }
    
    @Test
    mutating func multipleFiles() async throws {
        // Given an upload screen with multiple media files.
        setUpViewModel(urls: [fileURL, imageURL, fileURL], expectedCaption: nil)
        #expect(!context.viewState.shouldDisableInteraction)
        #expect(userIndicatorController.submitIndicatorDelayCallsCount == 0)
        
        // When attempting to send the files.
        let deferredDismiss = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.send(viewAction: .send)
        
        #expect(context.viewState.shouldDisableInteraction, "The interaction should be disabled while sending.")
        #expect(userIndicatorController.submitIndicatorDelayCallsCount == 1) // Loading indicator
        
        // Then the screen should be dismissed once all of the files have been sent.
        try await deferredDismiss.fulfill()
        #expect(timelineProxy.sendImageUrlThumbnailURLImageInfoCaptionRequestHandleCallsCount == 1)
        #expect(timelineProxy.sendFileUrlFileInfoCaptionRequestHandleCallsCount == 2)
        #expect(userIndicatorController.submitIndicatorDelayCallsCount == 1, "Only a loading indicator should be shown.")
    }
    
    @Test
    mutating func multipleFilesWithProcessingFailure() async throws {
        // Given an upload screen for a non-existent file.
        setUpViewModel(urls: [imageURL, fileURL, badImageURL], expectedCaption: nil)
        #expect(!context.viewState.shouldDisableInteraction)
        #expect(userIndicatorController.submitIndicatorDelayCallsCount == 0)
        
        // When attempting to send the file
        let deferredFailure = deferFailure(viewModel.actions, timeout: 1, message: "The screen should remain visible.") { $0 == .dismiss }
        context.send(viewAction: .send)
        #expect(context.viewState.shouldDisableInteraction, "The interaction should be disabled while sending.")
        #expect(userIndicatorController.submitIndicatorDelayCallsCount == 1) // Loading indicator
        
        // Then the failure should occur preventing the screen from being dismissed.
        try await deferredFailure.fulfill()
        #expect(!context.viewState.shouldDisableInteraction)
        #expect(userIndicatorController.submitIndicatorDelayCallsCount == 2, "An error indicator should be shown.")
    }
    
    @Test
    mutating func multipleFilesWithSendFailure() async throws {
        // Given an upload screen with multiple media files where one of the files will fail to send.
        setUpViewModel(urls: [fileURL, imageURL, imageURL, fileURL], expectedCaption: nil, simulateImageSendFailures: true)
        #expect(!context.viewState.shouldDisableInteraction)
        #expect(userIndicatorController.submitIndicatorDelayCallsCount == 0)
        
        // When attempting to send the files.
        let deferredDismiss = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.send(viewAction: .send)
        
        #expect(context.viewState.shouldDisableInteraction, "The interaction should be disabled while sending.")
        #expect(userIndicatorController.submitIndicatorDelayCallsCount == 1) // Loading indicator
        
        // Then the screen should be dismissed so the user can see which files made it into the timeline.
        try await deferredDismiss.fulfill()
        #expect(timelineProxy.sendImageUrlThumbnailURLImageInfoCaptionRequestHandleCallsCount == 2)
        #expect(timelineProxy.sendFileUrlFileInfoCaptionRequestHandleCallsCount == 2)
        #expect(userIndicatorController.submitIndicatorDelayCallsCount == 3, "Error indicators for each failure should be shown.")
    }
    
    // MARK: - Helpers
    
    private class BundleFinder {}
    
    private var audioURL: URL {
        assertResourceURL(filename: "test_audio.mp3")
    }
    
    private var fileURL: URL {
        assertResourceURL(filename: "test_pdf.pdf")
    }
    
    private var imageURL: URL {
        assertResourceURL(filename: "test_animated_image.gif")
    }
    
    private var videoURL: URL {
        assertResourceURL(filename: "landscape_test_video.mov")
    }
    
    private var badImageURL = URL(filePath: "/home/user/this_file_doesn't_exist.jpg")
    
    private func assertResourceURL(filename: String) -> URL {
        guard let url = Bundle(for: BundleFinder.self).url(forResource: filename, withExtension: nil) else {
            Issue.record("Failed retrieving test asset")
            return .picturesDirectory
        }
        return url
    }
    
    private mutating func setUpViewModel(urls: [URL],
                                         expectedCaption: String?,
                                         maxUploadSizeResult: Result<UInt, ClientProxyError>? = nil,
                                         simulateImageSendFailures: Bool = false) {
        timelineProxy = TimelineProxyMock(.init())
        timelineProxy.sendAudioUrlAudioInfoCaptionRequestHandleClosure = { [self] _, _, caption, _ in
            self.verifyCaption(caption, expectedCaption: expectedCaption)
        }
        timelineProxy.sendFileUrlFileInfoCaptionRequestHandleClosure = { [self] _, _, caption, _ in
            self.verifyCaption(caption, expectedCaption: expectedCaption)
        }
        timelineProxy.sendImageUrlThumbnailURLImageInfoCaptionRequestHandleClosure = { [self] _, _, _, caption, _ in
            guard !simulateImageSendFailures else { return .failure(.sdkError(TestError.unknown)) }
            return self.verifyCaption(caption, expectedCaption: expectedCaption)
        }
        timelineProxy.sendVideoUrlThumbnailURLVideoInfoCaptionRequestHandleClosure = { [self] _, _, _, caption, _ in
            self.verifyCaption(caption, expectedCaption: expectedCaption)
        }
        
        clientProxy = ClientProxyMock(.init())
        if let maxUploadSizeResult {
            clientProxy.underlyingMaxMediaUploadSize = maxUploadSizeResult
        }
        
        userIndicatorController = UserIndicatorControllerMock()
        
        viewModel = MediaUploadPreviewScreenViewModel(mediaURLs: urls,
                                                      title: "Some File",
                                                      isRoomEncrypted: true,
                                                      shouldShowCaptionWarning: true,
                                                      mediaUploadingPreprocessor: MediaUploadingPreprocessor(appSettings: ServiceLocator.shared.settings),
                                                      timelineController: MockTimelineController(timelineProxy: timelineProxy),
                                                      clientProxy: clientProxy,
                                                      userIndicatorController: userIndicatorController)
    }
    
    private func verifyCaption(_ caption: String?, expectedCaption: String?) -> Result<Void, TimelineProxyError> {
        guard caption == expectedCaption else {
            Issue.record("The sent caption '\(caption ?? "nil")' does not match the expected value '\(expectedCaption ?? "nil")'")
            return .failure(.sdkError(TestError.unexpectedParameter))
        }
        return .success(())
    }
    
    private func send() async throws {
        #expect(!context.viewState.shouldDisableInteraction, "Attempting to send when interaction is disabled.")
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.send(viewAction: .send)
        
        #expect(context.viewState.shouldDisableInteraction, "The interaction should be disabled while sending.")
        
        try await deferred.fulfill()
    }
}
