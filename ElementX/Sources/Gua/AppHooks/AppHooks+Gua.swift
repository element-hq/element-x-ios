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
        // Custom-scheme OIDC redirect. MAS's client-registration policy requires a
        // native redirect with NO authority (`scheme:/path`, not `scheme://host`) whose
        // reverse-DNS scheme matches the client_uri host — `global.gua` ⇄ `gua.global`.
        static let oidcRedirectURL = "global.gua:/oidc"
        static let localMasClientID = "01JXGA7E570000000000000000"

        // OIDC dynamic client registration requires client_uri, logo_uri, tos_uri and
        // policy_uri to all share a single host, and (for a custom-scheme redirect) that
        // host must be the scheme's reverse-DNS. The redirect scheme is `global.gua`, so
        // every URI below lives on `gua.global`. MAS only validates the hosts here — it
        // never fetches these URLs — so registration succeeds even before the pages exist.
        static let websiteURL: URL = "https://gua.global"
        static let logoURL: URL = "https://gua.global/gua-icon.png"
        static let copyrightURL: URL = "https://gua.global/copyright"
        static let acceptableUseURL: URL = "https://gua.global/terms"
        static let privacyURL: URL = "https://gua.global/privacy"
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
        // The account provider is injected, never hardcoded: an optional Info.plist override
        // (empty by default) wins, otherwise GuaDeployment supplies it — the production gua.global
        // host, or the dev host from the per-machine Secrets pipeline. Falls back to the existing
        // providers if nothing is configured.
        let injectedProvider = string(for: Constants.infoPlistAccountProviderKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedProvider = (injectedProvider?.isEmpty == false ? injectedProvider : nil) ?? GuaDeployment.current.defaultAccountProvider
        let accountProviders = resolvedProvider.map { [$0] } ?? appSettings.accountProviders
        let redirectURLString = string(for: Constants.infoPlistRedirectURLKey) ?? Constants.oidcRedirectURL

        guard let redirectURL = URL(string: redirectURLString) else {
            MXLog.error("Invalid OIDC redirect URL: \(Constants.oidcRedirectURL)")
            return appSettings
        }

        let staticRegistrations = makeStaticRegistrations()

        appSettings.override(accountProviders: accountProviders,
                             allowOtherAccountProviders: true,
                             hideBrandChrome: appSettings.hideBrandChrome,
                             pushGatewayBaseURL: appSettings.pushGatewayBaseURL,
                             oidcRedirectURL: redirectURL,
                             websiteURL: Constants.websiteURL,
                             logoURL: Constants.logoURL,
                             copyrightURL: Constants.copyrightURL,
                             acceptableUseURL: Constants.acceptableUseURL,
                             privacyURL: Constants.privacyURL,
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
