//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
struct RoomThreadListScreenViewModelTests {
    @Test
    func paginatesWhileOldestItemIsVisible() async throws {
        let (threadListServiceProxy, _) = makeThreadListServiceProxy(paginationState: .idle(endReached: false))
        let (paginateCalls, paginateContinuation) = AsyncStream<Void>.makeStream()
        threadListServiceProxy.paginateClosure = {
            paginateContinuation.yield()
            return .success(())
        }
        let viewModel = makeViewModel(threadListServiceProxy: threadListServiceProxy)

        let deferred = deferFulfillment(paginateCalls) { _ in true }
        viewModel.context.send(viewAction: .oldestItemDidAppear)
        try await deferred.fulfill()
    }

    @Test
    func paginationIndicatorStaysVisibleBetweenRequests() async throws {
        let (threadListServiceProxy, paginationStateSubject) = makeThreadListServiceProxy(paginationState: .idle(endReached: false))
        let viewModel = makeViewModel(threadListServiceProxy: threadListServiceProxy)
        let context = viewModel.context

        var deferred = deferFulfillment(context.observe(\.viewState.isPaginating)) { $0 }
        paginationStateSubject.send(.loading)
        try await deferred.fulfill()

        // The idle gap before the next request in the chain shouldn't hide the indicator.
        let deferredFailure = deferFailure(context.observe(\.viewState.isPaginating), timeout: .seconds(1)) { !$0 }
        paginationStateSubject.send(.idle(endReached: false))
        paginationStateSubject.send(.loading)
        try await deferredFailure.fulfill()

        // But once the requests stop, the indicator is hidden.
        deferred = deferFulfillment(context.observe(\.viewState.isPaginating)) { !$0 }
        paginationStateSubject.send(.idle(endReached: true))
        try await deferred.fulfill()
    }

    // MARK: - Helpers

    private func makeThreadListServiceProxy(paginationState: RoomThreadListPaginationState) -> (RoomThreadListServiceProxyMock, CurrentValueSubject<RoomThreadListPaginationState, Never>) {
        let paginationStateSubject = CurrentValueSubject<RoomThreadListPaginationState, Never>(paginationState)
        let threadListServiceProxy = RoomThreadListServiceProxyMock(.init())
        threadListServiceProxy.paginationStatePublisher = paginationStateSubject.asCurrentValuePublisher()
        return (threadListServiceProxy, paginationStateSubject)
    }

    private func makeViewModel(threadListServiceProxy: RoomThreadListServiceProxyMock) -> RoomThreadListScreenViewModel {
        RoomThreadListScreenViewModel(threadListServiceProxy: threadListServiceProxy, mediaProvider: MediaProviderMock(.init()))
    }
}
