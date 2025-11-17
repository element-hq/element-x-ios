//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias StickerPickerScreenViewModelType = StateStoreViewModelV2<StickerPickerScreenViewState, StickerPickerScreenViewAction>

protocol StickerPickerScreenViewModelProtocol {
    var actions: AnyPublisher<StickerPickerScreenCoordinatorAction, Never> { get }
    var context: StickerPickerScreenViewModelType.Context { get }
}

class StickerPickerScreenViewModel: StickerPickerScreenViewModelType, StickerPickerScreenViewModelProtocol {
    private let stickerPackService: StickerPackServiceProtocol
    private let clientProxy: ClientProxyProtocol
    private let actionsSubject: PassthroughSubject<StickerPickerScreenCoordinatorAction, Never> = .init()

    var actions: AnyPublisher<StickerPickerScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(stickerPackService: StickerPackServiceProtocol,
         clientProxy: ClientProxyProtocol) {
        self.stickerPackService = stickerPackService
        self.clientProxy = clientProxy

        super.init(initialViewState: StickerPickerScreenViewState())

        // Load sticker packs when initialized
        Task {
            await loadStickerPacks()
        }
    }

    override func process(viewAction: StickerPickerScreenViewAction) {
        switch viewAction {
        case .selectPack(let index):
            guard index >= 0, index < state.packs.count else {
                return
            }
            state.selectedPackIndex = index

        case .selectSticker(let sticker):
            actionsSubject.send(.stickerSelected(sticker))

        case .dismiss:
            actionsSubject.send(.cancel)

        case .retryLoading:
            Task {
                await loadStickerPacks()
            }
        }
    }

    // MARK: - Private

    private func loadStickerPacks() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let packs = try await stickerPackService.loadStickerPacks()
            state.packs = packs
            state.isLoading = false

            if !packs.isEmpty {
                state.selectedPackIndex = 0
            }
        } catch {
            MXLog.error("Failed to load sticker packs: \(error)")
            state.isLoading = false
            state.errorMessage = L10n.commonError
        }
    }
}
