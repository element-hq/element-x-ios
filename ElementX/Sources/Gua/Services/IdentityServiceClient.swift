//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
//

import Foundation

enum IdentityServiceError: Error, LocalizedError {
    case notConfigured
    case invalidURL
    case rateLimited
    case invalidOTP
    case invalidPin
    case pinLocked(retryAfterSeconds: Int?)
    case pinChangeCooldown(retryAfterSeconds: Int?)
    case pinChangeChallengeInvalid
    case invalidReauthToken
    case server(status: Int, message: String?)
    case transport(Error)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Identity service is not configured."
        case .invalidURL: "Identity service URL is invalid."
        case .rateLimited: "Too many attempts. Please wait a moment and try again."
        case .invalidOTP: "The code you entered is invalid or has expired."
        case .invalidPin: "That PIN is incorrect. Please try again."
        case let .pinLocked(retry):
            if let retry { "PIN locked due to too many wrong attempts. Try again in \(retry / 60) minute(s)." }
            else { "PIN locked due to too many wrong attempts. Try again later." }
        case let .pinChangeCooldown(retry):
            if let retry, retry > 0 {
                "For security, you can change your PIN again in \(max(1, Int((Double(retry) / 3600.0).rounded(.up)))) hour(s)."
            } else { "For security, you can only change your PIN once per day." }
        case .pinChangeChallengeInvalid: "Your PIN change session expired. Please start over."
        case .invalidReauthToken: "Your verification expired. Please request a new code."
        case let .server(status, message): message ?? "Server error (\(status))."
        case let .transport(error): error.localizedDescription
        case let .decoding(error): "Could not parse the server response: \(error.localizedDescription)"
        }
    }
}

@MainActor
protocol IdentityServiceClientProtocol {
    /// Contact discovery: match a batch of address-book phone numbers (E.164) against Gua
    /// accounts. The numbers are sent over TLS and digested server-side; only the contacts
    /// that are on Gua and discoverable come back.
    func lookupContacts(accessToken: String, phones: [String]) async throws -> [ContactMatch]
    func startAccountReauth(accessToken: String, language: String?) async throws
    func verifyAccountReauth(accessToken: String, code: String) async throws -> String
    func deactivateAccount(accessToken: String, reauthToken: String, eraseData: Bool) async throws
    func resetIdentityCredentials(accessToken: String, reauthToken: String) async throws -> IdentityResetCredentials
    // GUA FORK: Two-step verification (account PIN) management.
    func pinStatus(accessToken: String) async throws -> Bool
    func setInitialPin(accessToken: String, userId: String, newPin: String) async throws
    func startPinChange(accessToken: String, phone: String, currentPin: String) async throws -> String
    func completePinChange(accessToken: String, challengeId: String, otpCode: String, newPin: String) async throws
    /// Begins passkey enrollment and returns the IdP-hosted URL to load in an
    /// authenticated web session. The flow finishes when that page redirects to
    /// the app's OIDC redirect URL.
    func startPasskeyEnrollment(accessToken: String) async throws -> URL
}

/// Ephemeral credentials minted by the identity-service for the Matrix
/// `m.login.password` UIA stage during `client.resetIdentity()`.
struct IdentityResetCredentials: Equatable {
    let userId: String
    let password: String
}

/// A contact-discovery hit: an address-book phone number that belongs to a Gua account.
/// `phoneNumber` echoes back the submitted number so the client can map it onto the local
/// address book; `username` is the global Gua handle when one has been assigned.
struct ContactMatch: Equatable, Identifiable {
    let phoneNumber: String
    let userId: String
    let username: String?
    let displayName: String?

    var id: String {
        userId
    }
}

final class IdentityServiceClient: IdentityServiceClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        decoder = JSONDecoder()
        encoder = JSONEncoder()
    }

    /// Convenience initializer using the active `GuaDeployment`'s identity-service URL.
    convenience init?() {
        guard let url = GuaDeployment.current.identityServiceBaseURL else { return nil }
        self.init(baseURL: url)
    }

    // MARK: - Contact discovery

    func lookupContacts(accessToken: String, phones: [String]) async throws -> [ContactMatch] {
        struct Body: Encodable { let phones: [String] }
        struct Response: Decodable {
            struct Match: Decodable {
                let phone: String
                let userId: String
                let username: String?
                let displayName: String?
            }

            let matches: [Match]
        }
        let (data, _) = try await sendAuthenticated(path: "/directory/lookup",
                                                    accessToken: accessToken,
                                                    body: Body(phones: phones),
                                                    language: nil,
                                                    expectsBody: true)
        do {
            let response = try decoder.decode(Response.self, from: data)
            return response.matches.map {
                ContactMatch(phoneNumber: $0.phone, userId: $0.userId, username: $0.username, displayName: $0.displayName)
            }
        } catch {
            throw IdentityServiceError.decoding(error)
        }
    }

    // MARK: - Account reauthentication

    func startAccountReauth(accessToken: String, language: String?) async throws {
        struct EmptyBody: Encodable { }
        try await sendAuthenticated(path: "/account/reauth/start",
                                    accessToken: accessToken,
                                    body: EmptyBody(),
                                    language: language,
                                    expectsBody: false)
    }

    func verifyAccountReauth(accessToken: String, code: String) async throws -> String {
        struct Body: Encodable { let code: String }
        struct Response: Decodable { let reauthToken: String; let expiresInSeconds: Int }
        let (data, _) = try await sendAuthenticated(path: "/account/reauth/verify",
                                                    accessToken: accessToken,
                                                    body: Body(code: code),
                                                    language: nil,
                                                    expectsBody: true)
        do {
            return try decoder.decode(Response.self, from: data).reauthToken
        } catch {
            throw IdentityServiceError.decoding(error)
        }
    }

    func deactivateAccount(accessToken: String, reauthToken: String, eraseData: Bool) async throws {
        struct Body: Encodable { let reauthToken: String; let eraseData: Bool }
        try await sendAuthenticated(path: "/account/deactivate",
                                    accessToken: accessToken,
                                    body: Body(reauthToken: reauthToken, eraseData: eraseData),
                                    language: nil,
                                    expectsBody: false)
    }

    func resetIdentityCredentials(accessToken: String, reauthToken: String) async throws -> IdentityResetCredentials {
        struct Body: Encodable { let reauthToken: String }
        struct Response: Decodable { let userId: String; let password: String }
        let (data, _) = try await sendAuthenticated(path: "/account/reset-identity-credentials",
                                                    accessToken: accessToken,
                                                    body: Body(reauthToken: reauthToken),
                                                    language: nil,
                                                    expectsBody: true)
        do {
            let resp = try decoder.decode(Response.self, from: data)
            return IdentityResetCredentials(userId: resp.userId, password: resp.password)
        } catch {
            throw IdentityServiceError.decoding(error)
        }
    }

    // MARK: - Two-step verification (PIN)

    func pinStatus(accessToken: String) async throws -> Bool {
        struct Response: Decodable { let hasPin: Bool }
        guard let url = URL(string: "/security/pin/status", relativeTo: baseURL) else {
            throw IdentityServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw IdentityServiceError.transport(error)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IdentityServiceError.server(status: -1, message: "Non-HTTP response.")
        }
        guard httpResponse.statusCode == 200 else {
            let message = (try? decoder.decode(ErrorBody.self, from: data)).flatMap { $0.message ?? $0.error }
            throw IdentityServiceError.server(status: httpResponse.statusCode, message: message)
        }
        do {
            return try decoder.decode(Response.self, from: data).hasPin
        } catch {
            throw IdentityServiceError.decoding(error)
        }
    }

    func setInitialPin(accessToken: String, userId: String, newPin: String) async throws {
        struct Body: Encodable {
            let userId: String
            let newPin: String
        }
        try await sendAuthenticated(path: "/security/pin",
                                    accessToken: accessToken,
                                    body: Body(userId: userId, newPin: newPin),
                                    language: nil,
                                    expectsBody: false)
    }

    func startPinChange(accessToken: String, phone: String, currentPin: String) async throws -> String {
        struct Body: Encodable {
            let phone: String
            let currentPin: String
        }
        struct Response: Decodable {
            let challengeId: String
            let expiresInSeconds: Int?
        }
        let (data, _) = try await sendAuthenticated(path: "/security/pin/change/start",
                                                    accessToken: accessToken,
                                                    body: Body(phone: phone, currentPin: currentPin),
                                                    language: nil,
                                                    expectsBody: true)
        do {
            return try decoder.decode(Response.self, from: data).challengeId
        } catch {
            throw IdentityServiceError.decoding(error)
        }
    }

    func completePinChange(accessToken: String, challengeId: String, otpCode: String, newPin: String) async throws {
        struct Body: Encodable {
            let challengeId: String
            let otpCode: String
            let newPin: String
        }
        try await sendAuthenticated(path: "/security/pin/change/complete",
                                    accessToken: accessToken,
                                    body: Body(challengeId: challengeId, otpCode: otpCode, newPin: newPin),
                                    language: nil,
                                    expectsBody: false)
    }

    // MARK: - Passkey enrollment

    func startPasskeyEnrollment(accessToken: String) async throws -> URL {
        struct EmptyBody: Encodable { }
        struct Response: Decodable { let enrollUrl: String }
        let (data, _) = try await sendAuthenticated(path: "/security/passkey/enroll/start",
                                                    accessToken: accessToken,
                                                    body: EmptyBody(),
                                                    language: Locale.current.language.languageCode?.identifier,
                                                    expectsBody: true)
        do {
            let response = try decoder.decode(Response.self, from: data)
            guard let url = URL(string: response.enrollUrl) else {
                throw IdentityServiceError.invalidURL
            }
            return url
        } catch let error as IdentityServiceError {
            throw error
        } catch {
            throw IdentityServiceError.decoding(error)
        }
    }

    @discardableResult
    private func sendAuthenticated(path: String,
                                   accessToken: String,
                                   body: some Encodable,
                                   language: String?,
                                   expectsBody: Bool) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw IdentityServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if let language { request.setValue(language, forHTTPHeaderField: "Accept-Language") }
        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw IdentityServiceError.transport(error)
        }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw IdentityServiceError.transport(error)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IdentityServiceError.server(status: -1, message: "Non-HTTP response.")
        }

        switch httpResponse.statusCode {
        case 200, 202, 204:
            return (data, httpResponse)
        case 400:
            let errorBody = try? decoder.decode(ErrorBody.self, from: data)
            if errorBody?.code == "invalid_otp" { throw IdentityServiceError.invalidOTP }
            if errorBody?.code == "invalid_pin" { throw IdentityServiceError.invalidPin }
            throw IdentityServiceError.server(status: 400, message: errorBody?.message ?? errorBody?.error)
        case 401:
            let errorBody = try? decoder.decode(ErrorBody.self, from: data)
            if errorBody?.code == "invalid_reauth_token" {
                throw IdentityServiceError.invalidReauthToken
            }
            if errorBody?.code == "invalid_otp" {
                throw IdentityServiceError.invalidOTP
            }
            if errorBody?.code == "pin_change_challenge_invalid" {
                throw IdentityServiceError.pinChangeChallengeInvalid
            }
            throw IdentityServiceError.server(status: 401, message: errorBody?.message ?? errorBody?.error)
        case 425:
            let errorBody = try? decoder.decode(ErrorBody.self, from: data)
            let retry = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
            if errorBody?.code == "pin_change_cooldown" {
                throw IdentityServiceError.pinChangeCooldown(retryAfterSeconds: retry)
            }
            throw IdentityServiceError.server(status: 425, message: errorBody?.message ?? errorBody?.error)
        case 429:
            let errorBody = try? decoder.decode(ErrorBody.self, from: data)
            if errorBody?.code == "pin_locked" {
                throw IdentityServiceError.pinLocked(retryAfterSeconds: nil)
            }
            throw IdentityServiceError.rateLimited
        default:
            let message = (try? decoder.decode(ErrorBody.self, from: data)).flatMap { $0.message ?? $0.errorDescription ?? $0.error }
            throw IdentityServiceError.server(status: httpResponse.statusCode, message: message)
        }
    }

    // MARK: - Private

    private struct ErrorBody: Decodable {
        let code: String?
        let message: String?
        let error: String?
        let errorDescription: String?

        enum CodingKeys: String, CodingKey {
            case code
            case message
            case error
            case errorDescription = "error_description"
        }
    }
}
