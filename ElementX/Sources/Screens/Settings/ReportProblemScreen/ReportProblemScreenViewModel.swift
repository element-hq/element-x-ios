//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import DeviceKit
import SwiftUI
import UIKit

typealias ReportProblemScreenViewModelType = StateStoreViewModelV2<ReportProblemScreenViewState, ReportProblemScreenViewAction>

class ReportProblemScreenViewModel: ReportProblemScreenViewModelType, ReportProblemScreenViewModelProtocol {
    private let userSession: UserSessionProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let actionsSubject: PassthroughSubject<ReportProblemScreenViewModelAction, Never> = .init()

    var actions: AnyPublisher<ReportProblemScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(userSession: UserSessionProtocol, userIndicatorController: UserIndicatorControllerProtocol) {
        self.userSession = userSession
        self.userIndicatorController = userIndicatorController

        let diagnosticInfo = Self.generateDiagnosticInfo(userSession: userSession)
        super.init(initialViewState: ReportProblemScreenViewState(diagnosticInfo: diagnosticInfo))
    }

    override func process(viewAction: ReportProblemScreenViewAction) {
        switch viewAction {
        case .copyToClipboard:
            UIPasteboard.general.string = generateReportText()
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.commonCopiedToClipboard, iconName: "checkmark"))
        case .share:
            state.reportTextForSharing = generateReportText()
            state.bindings.showShareSheet = true
        }
    }

    private func generateReportText() -> String {
        let description = state.bindings.problemDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let problemText = description.isEmpty ? L10n.screenReportProblemNoDescription : description
        return L10n.screenReportProblemReportText(problemText, state.diagnosticInfo)
    }

    private static func generateDiagnosticInfo(userSession: UserSessionProtocol) -> String {
        let appVersion = InfoPlistReader.main.bundleShortVersionString
        let buildNumber = InfoPlistReader.main.bundleVersion
        let iosVersion = UIDevice.current.systemVersion
        let deviceModel = Device.current.safeDescription
        let locale = Locale.preferredLanguages.first ?? L10n.screenReportProblemUnknown
        let timezone = TimeZone.current.identifier
        let userID = userSession.clientProxy.userID
        let deviceID = userSession.clientProxy.deviceID ?? L10n.screenReportProblemUnknown

        return L10n.screenReportProblemDiagnosticInfo(appVersion,
                                                      buildNumber,
                                                      iosVersion,
                                                      deviceModel,
                                                      locale,
                                                      timezone,
                                                      userID,
                                                      deviceID)
    }
}
