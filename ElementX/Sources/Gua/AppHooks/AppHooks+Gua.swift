//
// Copyright 2025
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

#if IS_MAIN_APP
private struct GuaAppSettingsHook: AppSettingsHookProtocol {
    private enum Constants {
        static let defaultAccountProvider = "dev.gua.sarahlacerda.me"
        static let oidcRedirectURL = "me.sarahlacerda.gua://oidc"
        static let localMasClientID = "01JXGA7E570000000000000000"
        static let localStaticRegistrationURLs = [
            "http://localhost:8008",
            "http://localhost:8008/",
            "http://localhost:8090",
            "http://localhost:8090/"
        ]
        static let infoPlistAccountProviderKey = "GuaDefaultAccountProvider"
        static let infoPlistRedirectURLKey = "GuaOidcRedirectURL"
        static let infoPlistStaticRegistrationsKey = "GuaOidcStaticRegistrations"
    }

    func configure(_ appSettings: AppSettings) -> AppSettings {
        let accountProvider = string(for: Constants.infoPlistAccountProviderKey) ?? Constants.defaultAccountProvider
        let redirectURLString = string(for: Constants.infoPlistRedirectURLKey) ?? Constants.oidcRedirectURL

        guard let redirectURL = URL(string: redirectURLString) else {
            MXLog.error("Invalid OIDC redirect URL: \(Constants.oidcRedirectURL)")
            return appSettings
        }

        let staticRegistrations = makeStaticRegistrations()

        appSettings.override(accountProviders: [accountProvider],
                             allowOtherAccountProviders: true,
                             hideBrandChrome: appSettings.hideBrandChrome,
                             pushGatewayBaseURL: appSettings.pushGatewayBaseURL,
                             oidcRedirectURL: redirectURL,
                             websiteURL: appSettings.websiteURL,
                             logoURL: appSettings.logoURL,
                             copyrightURL: appSettings.copyrightURL,
                             acceptableUseURL: appSettings.acceptableUseURL,
                             privacyURL: appSettings.privacyURL,
                             encryptionURL: appSettings.encryptionURL,
                             deviceVerificationURL: appSettings.deviceVerificationURL,
                             chatBackupDetailsURL: appSettings.chatBackupDetailsURL,
                             identityPinningViolationDetailsURL: appSettings.identityPinningViolationDetailsURL,
                             elementWebHosts: appSettings.elementWebHosts,
                             accountProvisioningHost: appSettings.accountProvisioningHost,
                             bugReportApplicationID: appSettings.bugReportApplicationID,
                             analyticsTermsURL: appSettings.analyticsTermsURL,
                             mapTilerConfiguration: appSettings.mapTilerConfiguration,
                             oidcStaticRegistrations: staticRegistrations)

        return appSettings
    }

    private func string(for key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }

    private func makeStaticRegistrations() -> [URL: String]? {
        var result: [URL: String] = [:]

        for staticRegistrationURLString in Constants.localStaticRegistrationURLs {
            guard let staticRegistrationURL = URL(string: staticRegistrationURLString) else { continue }
            result[staticRegistrationURL] = Constants.localMasClientID
        }

        guard let rawValue = string(for: Constants.infoPlistStaticRegistrationsKey)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawValue.isEmpty else {
            return result.isEmpty ? nil : result
        }

        let pairs = rawValue.split(separator: ",")

        for pair in pairs {
            let components = pair.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard components.count == 2, let url = URL(string: components[0]) else {
                MXLog.error("Ignoring invalid OIDC static registration entry: \(pair)")
                continue
            }
            result[url] = components[1]
        }

        return result.isEmpty ? nil : result
    }
}
#endif

extension AppHooks {
    func setUp() {
        #if IS_MAIN_APP
        registerAppSettingsHook(GuaAppSettingsHook())
        #endif
    }
}
