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
    
    // MARK: - Prewarming
    
    private static var hasPrewarmed = false
    
    /// Renders a throwaway picker once, off-screen inside the real window (so the graph
    /// resolves against the real environment), so the first real presentation doesn't
    /// pay for emoji glyph rasterisation and the sheet appears quickly on double-tap.
    static func prewarm(emojiProvider: EmojiProviderProtocol, in window: UIWindow?) {
        guard !hasPrewarmed else { return }
        hasPrewarmed = true
        
        let startDate = Date()
        
        let (_, continuation) = AsyncStream.makeStream(of: String.self)
        let coordinator = EmojiPickerScreenCoordinator(parameters: .init(mode: .reaction,
                                                                         selectedEmojis: [],
                                                                         emojiProvider: emojiProvider,
                                                                         continuation: continuation))
        
        guard let view = UIHostingController(rootView: coordinator.toPresentable()).view else { return }
        if let window {
            view.frame = window.bounds.offsetBy(dx: window.bounds.width * 2, dy: 0)
            window.addSubview(view)
        } else {
            view.frame = CGRect(origin: .zero, size: UIScreen.main.bounds.size)
        }
        view.layoutIfNeeded()
        
        // Layout alone doesn't draw: an actual render warms the emoji glyph caches.
        _ = UIGraphicsImageRenderer(bounds: view.bounds).image { view.layer.render(in: $0.cgContext) }
        view.removeFromSuperview()
        
        continuation.finish()
        
        MXLog.info("Prewarmed the emoji picker in \(Int(Date().timeIntervalSince(startDate) * 1000))ms")
    }
}
