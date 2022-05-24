//
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI
import Combine

struct HomeScreenCoordinatorParameters {
    let userSession: UserSession
    let mediaProvider: MediaProviderProtocol
    let attributedStringBuilder: AttributedStringBuilderProtocol
    let memberDetailProviderManager: MemberDetailProviderManager
}

enum HomeScreenCoordinatorResult {
    case logout
    case selectRoom(roomIdentifier: String)
}

final class HomeScreenCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: HomeScreenCoordinatorParameters
    private let hostingController: UIViewController
    private var viewModel: HomeScreenViewModelProtocol
    
    private var roomSummaries: [RoomSummary] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((HomeScreenCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: HomeScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = HomeScreenViewModel(attributedStringBuilder: parameters.attributedStringBuilder)
        
        let view = HomeScreen(context: viewModel.context)
        hostingController = UIHostingController(rootView: view)
        
        viewModel.completion = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .logout:
                self.completion?(.logout)
            case .selectRoom(let roomIdentifier):
                self.completion?(.selectRoom(roomIdentifier: roomIdentifier))
            }
        }
        
        parameters.userSession
            .callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                switch result {
                case .updatedRoomsList:
                    self?.updateRoomsList()
                }
            }.store(in: &cancellables)
        
        updateRoomsList()
        
        Task {
            if case let .success(userAvatarURL) = await parameters.userSession.loadUserAvatarURL() {
                if case let .success(avatar) = await parameters.mediaProvider.loadImageFromURL(userAvatarURL) {
                    await MainActor.run {
                        self.viewModel.updateWithUserAvatar(avatar)
                    }
                }
            }
            
            if case let .success(userDisplayName) = await parameters.userSession.loadUserDisplayName() {
                await MainActor.run {
                    self.viewModel.updateWithUserDisplayName(userDisplayName)
                }
            }
        }
    }
    
    // MARK: - Public
    func start() {
        
    }
    
    func toPresentable() -> UIViewController {
        return self.hostingController
    }
    
    // MARK: - Private
    
    func updateRoomsList() {
        self.roomSummaries = parameters.userSession.rooms.compactMap { roomProxy in
            guard !roomProxy.isSpace, !roomProxy.isTombstoned else {
                return nil
            }
            
            if let summary = self.roomSummaries.first(where: { $0.id == roomProxy.id }) {
                return summary
            }
            
            let memberDetailProvider = parameters.memberDetailProviderManager.memberDetailProviderForRoomProxy(roomProxy)
            
            return RoomSummary(roomProxy: roomProxy,
                               mediaProvider: parameters.mediaProvider,
                               eventBriefFactory: EventBriefFactory(memberDetailProvider: memberDetailProvider))
        }
        
        self.viewModel.updateWithRoomList(roomSummaries)
    }
}
