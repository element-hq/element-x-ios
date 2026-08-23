//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI
import UIKit

struct EmojiPickerScreenCoordinatorParameters {
    let mode: EmojiPickerScreenMode
    /// Any emojis that should be displayed as already selected.
    let selectedEmojis: Set<String>
    let emojiProvider: EmojiProviderProtocol
    /// A continuation that yields the selected emoji.
    let continuation: EmojiPickerScreenContinuation
}

enum EmojiPickerScreenCoordinatorAction {
    case dismiss
}

final class EmojiPickerScreenCoordinator: CoordinatorProtocol {
    private var viewModel: EmojiPickerScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<EmojiPickerScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<EmojiPickerScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: EmojiPickerScreenCoordinatorParameters) {
        viewModel = EmojiPickerScreenViewModel(mode: parameters.mode,
                                               selectedEmojis: parameters.selectedEmojis,
                                               emojiProvider: parameters.emojiProvider,
                                               continuation: parameters.continuation)
    }
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    actionsSubject.send(.dismiss)
                }
            }
            .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }
    
    func toPresentable() -> AnyView {
        AnyView(EmojiPickerScreen(context: viewModel.context))
    }
    
    // MARK: - Instant presentation
    
    /// One picker instance is built ahead of time and re-presented forever: SwiftUI rebuilds a
    /// sheet's entire view graph on every `.sheet` presentation (~110ms of double-tap-to-sheet
    /// latency), whereas re-presenting a cached hosting controller via UIKit takes a frame.
    private static var cached: (coordinator: EmojiPickerScreenCoordinator, hostingController: EmojiPickerHostingController)?
    private static var cachedCancellables = Set<AnyCancellable>()
    
    /// Builds (and renders once, off-screen) the cached picker so the first real
    /// presentation doesn't pay for view building or emoji glyph rasterisation.
    static func prewarm(emojiProvider: EmojiProviderProtocol) {
        guard cached == nil else { return }
        
        let startDate = Date()
        
        let (_, continuation) = AsyncStream.makeStream(of: String.self)
        let coordinator = EmojiPickerScreenCoordinator(parameters: .init(mode: .reaction,
                                                                         selectedEmojis: [],
                                                                         emojiProvider: emojiProvider,
                                                                         continuation: continuation))
        coordinator.start()
        coordinator.actions
            .sink { action in
                switch action {
                case .dismiss:
                    cached?.hostingController.dismiss(animated: true)
                }
            }
            .store(in: &cachedCancellables)
        
        let hostingController = EmojiPickerHostingController(rootView: coordinator.toPresentable())
        let view = hostingController.view!
        view.frame = CGRect(origin: .zero, size: UIScreen.main.bounds.size)
        view.layoutIfNeeded()
        
        // Layout alone doesn't draw: an actual render warms the emoji glyph caches.
        _ = UIGraphicsImageRenderer(bounds: view.bounds).image { view.layer.render(in: $0.cgContext) }
        
        continuation.finish()
        cached = (coordinator, hostingController)
        
        MXLog.info("Prewarmed the emoji picker in \(Int(Date().timeIntervalSince(startDate) * 1000))ms")
    }
    
    /// Instantly presents the cached picker over `presenter` as an unanimated UIKit sheet.
    /// `onDismiss` fires once on any dismissal (selection, toolbar or swipe-down), after the
    /// current continuation is finished.
    static func presentCached(over presenter: UIViewController,
                              emojiProvider: EmojiProviderProtocol,
                              selectedEmojis: Set<String>,
                              continuation: EmojiPickerScreenContinuation,
                              onDismiss: @escaping () -> Void) {
        prewarm(emojiProvider: emojiProvider)
        guard let cached, cached.hostingController.presentingViewController == nil else {
            MXLog.error("Cached emoji picker unavailable or already presented")
            continuation.finish()
            onDismiss()
            return
        }
        
        cached.coordinator.viewModel.prepareForPresentation(selectedEmojis: selectedEmojis, continuation: continuation)
        
        if let sheet = cached.hostingController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        cached.hostingController.onDismiss = { [weak coordinator = cached.coordinator] in
            coordinator?.stop() // Finish the continuation on swipe-down too.
            onDismiss()
        }
        presenter.present(cached.hostingController, animated: false)
    }
    
    /// Dismisses the cached picker if it's currently presented. For navigation that leaves
    /// the picker's state some other way (deep link, flow dismissal): as a UIKit-presented
    /// sheet it isn't implicitly removed by SwiftUI navigation changes.
    static func dismissCached() {
        guard let cached, cached.hostingController.presentingViewController != nil else { return }
        cached.hostingController.dismiss(animated: false)
    }
}

/// Fires `onDismiss` whenever the presented picker leaves the screen, whichever way
/// it was dismissed.
private final class EmojiPickerHostingController: UIHostingController<AnyView> {
    var onDismiss: (() -> Void)?
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDismiss?()
        onDismiss = nil
    }
}
