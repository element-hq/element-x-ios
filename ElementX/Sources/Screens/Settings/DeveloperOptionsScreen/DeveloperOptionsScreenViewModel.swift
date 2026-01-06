//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias DeveloperOptionsScreenViewModelType = StateStoreViewModelV2<DeveloperOptionsScreenViewState, DeveloperOptionsScreenViewAction>

class DeveloperOptionsScreenViewModel: DeveloperOptionsScreenViewModelType, DeveloperOptionsScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<DeveloperOptionsScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<DeveloperOptionsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(developerOptions: DeveloperOptionsProtocol, elementCallBaseURL: URL, appHooks: AppHooks, clientProxy: ClientProxyProtocol) {
        super.init(initialViewState: .init(elementCallBaseURL: elementCallBaseURL,
                                           appHooks: appHooks,
                                           bindings: .init(developerOptions: developerOptions)))
        
        Task {
            if case let .success(sizes) = await clientProxy.storeSizes() {
                let formatter = ByteCountFormatStyle(style: .file)
                
                var components = [DeveloperOptionsScreenViewState.StoreSize]()
                if let cryptoStore = sizes.cryptoStore {
                    components.append(.init(name: "CryptoStore", size: formatter.format(Int64(cryptoStore))))
                }
                if let stateStore = sizes.stateStore {
                    components.append(.init(name: "StateStore", size: formatter.format(Int64(stateStore))))
                }
                if let eventCacheStore = sizes.eventCacheStore {
                    components.append(.init(name: "EventCacheStore", size: formatter.format(Int64(eventCacheStore))))
                }
                if let mediaStore = sizes.mediaStore {
                    components.append(.init(name: "MediaStore", size: formatter.format(Int64(mediaStore))))
                }
                if let logsSize = try? FileManager.default.sizeForDirectory(at: .appGroupLogsDirectory) {
                    components.append(.init(name: "Log Files", size: formatter.format(Int64(logsSize))))
                }
            
                state.storeSizes = components
            }
        }
    }
    
    override func process(viewAction: DeveloperOptionsScreenViewAction) {
        switch viewAction {
        case .clearCache:
            actionsSubject.send(.clearCache)
        }
    }
}
