//
// Copyright 2022 New Vector Ltd
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

import Combine
import SwiftUI

struct EncryptionResetPasswordScreenCoordinatorParameters { }

enum EncryptionResetPasswordScreenCoordinatorAction: CustomStringConvertible {
    case resetIdentity(String)
    
    var description: String {
        switch self {
        case .resetIdentity:
            "resetIdentity"
        }
    }
}

final class EncryptionResetPasswordScreenCoordinator: CoordinatorProtocol {
    private let parameters: EncryptionResetPasswordScreenCoordinatorParameters
    private let viewModel: EncryptionResetPasswordScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<EncryptionResetPasswordScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<EncryptionResetPasswordScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: EncryptionResetPasswordScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = EncryptionResetPasswordScreenViewModel()
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .resetIdentity(let password):
                self.actionsSubject.send(.resetIdentity(password))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(EncryptionResetPasswordScreen(context: viewModel.context))
    }
}
