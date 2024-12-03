//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias CompleteProfileScreenViewModelType = StateStoreViewModel<CompleteProfileScreenViewState, CompleteProfileScreenViewAction>

class CompleteProfileScreenViewModel: CompleteProfileScreenViewModelType, CompleteProfileScreenViewModelProtocol {
    private let authenticationService: AuthenticationServiceProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    
    private var actionsSubject: PassthroughSubject<CompleteProfileScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<CompleteProfileScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(authenticationService: AuthenticationServiceProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         mediaUploadingPreprocessor: MediaUploadingPreprocessor,
         inviteCode: String) {
        self.authenticationService = authenticationService
        self.userIndicatorController = userIndicatorController
        self.mediaUploadingPreprocessor = mediaUploadingPreprocessor
        
        super.init(initialViewState: CompleteProfileScreenViewState(inviteCode: inviteCode))
    }
    
    override func process(viewAction: CompleteProfileScreenViewAction) {
        switch viewAction {
        case .presentMediaSource:
            state.bindings.showMediaSheet = true
        case .displayCameraPicker:
            actionsSubject.send(.displayCameraPicker)
        case .displayMediaPicker:
            actionsSubject.send(.displayMediaPicker)
        case .completeProfile:
            updateUserProfile()
        }
    }
    
    func didSelectMediaURL(url: URL) {
        Task {
            let userIndicatorID = UUID().uuidString
            defer {
                userIndicatorController.retractIndicatorWithId(userIndicatorID)
            }
            userIndicatorController.submitIndicator(UserIndicator(id: userIndicatorID,
                                                                  type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                                  title: L10n.commonLoading,
                                                                  persistent: true))
            
            let mediaResult = await mediaUploadingPreprocessor.processMedia(at: url)
            
            switch mediaResult {
            case .success(.image):
                state.localMedia = try? mediaResult.get()
            case .failure, .success:
                userIndicatorController.alertInfo = .init(id: .init(), title: L10n.commonError, message: L10n.errorUnknown)
            }
        }
    }
    
    private func updateUserProfile() {
        
    }
    
    private static let loadingIndicatorIdentifier = "\(CompleteProfileScreenCoordinatorAction.self)-Loading"
    
    private func startLoading() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal,
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func stopLoading() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
    
    private func handleError(error: AuthenticationServiceError) {
        userIndicatorController.alertInfo = AlertInfo(id: UUID())
    }
}
