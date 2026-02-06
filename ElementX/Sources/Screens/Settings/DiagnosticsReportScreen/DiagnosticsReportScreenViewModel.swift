//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias DiagnosticsReportScreenViewModelType = StateStoreViewModelV2<DiagnosticsReportScreenViewState, DiagnosticsReportScreenViewAction>

class DiagnosticsReportScreenViewModel: DiagnosticsReportScreenViewModelType, DiagnosticsReportScreenViewModelProtocol {
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<DiagnosticsReportScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<DiagnosticsReportScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol?, userIndicatorController: UserIndicatorControllerProtocol) {
        self.userIndicatorController = userIndicatorController
        
        let template = DiagnosticsTemplateBuilder.buildTemplate(userSession: userSession)
        super.init(initialViewState: .init(bindings: .init(reportText: template)))
    }
    
    override func process(viewAction: DiagnosticsReportScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .copyToClipboard:
            UIPasteboard.general.string = state.bindings.reportText
            userIndicatorController.submitIndicator(.init(title: L10n.commonCopiedToClipboard))
        case .share:
            state.bindings.isSharePresented = true
        }
    }
}
