//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

class AccessibilityTestsAppCoordinator: AppCoordinatorProtocol {
    var windowManager: any SecureWindowManagerProtocol
    
    func handleDeepLink(_ url: URL, isExternalURL: Bool) -> Bool {
        fatalError("Not implemented")
    }
    
    func handlePotentialPhishingAttempt(url: URL, openURLAction: @escaping (URL) -> Void) -> Bool {
        fatalError("Not implemented")
    }
    
    func handleUserActivity(_ userActivity: NSUserActivity) {
        fatalError("Not implemented")
    }
    
    private let previewsWrapper: PreviewsWrapper
    
    private var cancellables = Set<AnyCancellable>()
    
    init(appDelegate: AppDelegate) {
        windowManager = WindowManager(appDelegate: appDelegate)
        // disabling View animations
        UIView.setAnimationsEnabled(false)
        
        MXLog.configure(currentTarget: "accessibility-tests")
        
        ServiceLocator.shared.register(userIndicatorController: UserIndicatorController())
        
        AppSettings.configureWithSuiteName("io.element.elementx.accessibilitytests")
        AppSettings.resetAllSettings()
        ServiceLocator.shared.register(appSettings: AppSettings())
        ServiceLocator.shared.register(bugReportService: BugReportServiceMock(.init()))
        
        let analyticsClient = AnalyticsClientMock()
        analyticsClient.isRunning = false
        ServiceLocator.shared.register(analytics: AnalyticsService(client: analyticsClient,
                                                                   appSettings: ServiceLocator.shared.settings))
        
        guard let name = ProcessInfo.accessibilityViewID,
              let previewType = TestablePreviewsDictionary.dictionary[name] else {
            fatalError("Unable to launch with unknown screen.")
        }
        previewsWrapper = .init(name: name, previews: previewType._allPreviews)
        
        setupSignalling()
    }
    
    func toPresentable() -> AnyView {
        AnyView(PreviewsWrapperView(wrapper: previewsWrapper))
    }
    
    private func setupSignalling() {
        do {
            let client = try UITestsSignalling.Client(mode: .app)
            client.signals.sink { [weak self] signal in
                guard let self else { return }
                switch signal {
                case .accessibilityAudit(let auditSignal):
                    switch auditSignal {
                    case .nextPreview:
                        Task { [weak self] in
                            guard let self else { return }
                            await previewsWrapper.updateCurrentIndex()
                            do {
                                guard !previewsWrapper.isDone else {
                                    try client.send(.accessibilityAudit(.noMorePreviews))
                                    return
                                }
                                
                                try client.send(.accessibilityAudit(.nextPreviewReady(name: previewsWrapper.previewName)))
                            } catch {
                                fatalError("Failed sending signal: \(signal)")
                            }
                        }
                    default:
                        break
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
        } catch {
            fatalError("Unable to start client signalling")
        }
    }
}

struct PreviewsWrapperView: View {
    let wrapper: PreviewsWrapper
    
    var body: some View {
        if wrapper.currentIndex < 0 || wrapper.isDone {
            EmptyView()
        } else {
            wrapper.currentPreview.content
                .id(wrapper.previewName)
        }
    }
}

@Observable final class PreviewsWrapper {
    private let name: String
    private let previews: [_Preview]
    private(set) var currentIndex = -1
    var currentPreview: _Preview { previews[currentIndex] }
    
    private(set) var isDone = false
    
    var previewName: String {
        "\(name)-\(currentPreview.displayName ?? String(currentIndex))"
    }
    
    init(name: String, previews: [_Preview]) {
        self.name = name
        self.previews = previews
    }
    
    @MainActor
    func updateCurrentIndex() async {
        let newIndex = currentIndex + 1
        guard newIndex < previews.count else {
            isDone = true
            return
        }
        let newPreview = previews[newIndex]
        var fulfillmentSource: SnapshotFulfillmentPreferenceKey.Source?
        let preferenceReadingView = newPreview.content.onPreferenceChange(SnapshotFulfillmentPreferenceKey.self) { fulfillmentSource = $0?.source }
        
        // Render an image of the view in order to trigger the preference updates to occur.
        let imageRenderer = ImageRenderer(content: preferenceReadingView)
        _ = imageRenderer.uiImage
        
        switch fulfillmentSource {
        case .publisher(let publisher):
            _ = await publisher.values.first { $0 == true }
        case .stream(let stream):
            _ = await stream.first { $0 == true }
        case .none:
            break
        }
        
        currentIndex = newIndex
    }
}
