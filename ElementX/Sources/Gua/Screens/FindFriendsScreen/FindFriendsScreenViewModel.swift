//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
//

import Combine
import SwiftUI
import UIKit

typealias FindFriendsScreenViewModelType = StateStoreViewModelV2<FindFriendsScreenViewState, FindFriendsScreenViewAction>

class FindFriendsScreenViewModel: FindFriendsScreenViewModelType, FindFriendsScreenViewModelProtocol {
    private let contactDiscoveryService: ContactDiscoveryServiceProtocol
    private let clientProxy: ClientProxyProtocol
    private let accessToken: String

    private let actionsSubject: PassthroughSubject<FindFriendsScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<FindFriendsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(contactDiscoveryService: ContactDiscoveryServiceProtocol,
         clientProxy: ClientProxyProtocol,
         accessToken: String) {
        self.contactDiscoveryService = contactDiscoveryService
        self.clientProxy = clientProxy
        self.accessToken = accessToken

        super.init(initialViewState: FindFriendsScreenViewState())

        Task { await discover() }
    }

    override func process(viewAction: FindFriendsScreenViewAction) {
        switch viewAction {
        case .retry:
            Task { await discover() }
        case .openSystemSettings:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case let .selectContact(contact):
            Task { await startChat(with: contact) }
        case .close:
            actionsSubject.send(.close)
        }
    }

    // MARK: - Private

    private func discover() async {
        state.phase = .loading
        state.errorMessage = nil

        let status = contactDiscoveryService.authorizationStatus
        if status == .denied || status == .restricted {
            state.phase = .needsPermission
            return
        }

        do {
            let contacts = try await contactDiscoveryService.discover(accessToken: accessToken)
            state.contacts = contacts
            state.phase = contacts.isEmpty ? .empty : .loaded
        } catch ContactDiscoveryError.accessDenied {
            state.phase = .needsPermission
        } catch ContactDiscoveryError.noContactsWithNumbers {
            state.contacts = []
            state.phase = .empty
        } catch {
            state.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state.phase = .error
        }
    }

    private func startChat(with contact: DiscoveredContact) async {
        guard state.startingChatUserID == nil else { return }
        state.startingChatUserID = contact.userId
        defer { state.startingChatUserID = nil }

        // Reuse an existing direct room when there is one.
        if case let .success(existingRoomID) = clientProxy.directRoomForUserID(contact.userId),
           let roomID = existingRoomID {
            actionsSubject.send(.startedChat(roomID: roomID))
            return
        }

        switch await clientProxy.createDirectRoom(with: contact.userId, expectedRoomName: contact.localName) {
        case let .success(roomID):
            actionsSubject.send(.startedChat(roomID: roomID))
        case .failure:
            state.bindings.alertInfo = AlertInfo(id: UUID(),
                                                 title: "Couldn't start the chat",
                                                 message: "Something went wrong starting a chat with \(contact.localName). Please try again.")
        }
    }
}
