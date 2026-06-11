//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
//

import Foundation

/// A Matrix session minted by the Gua identity-service after a successful OTP verification.
struct IdentityServiceMatrixSession: Equatable, Sendable {
    let accessToken: String
    let userId: String
    let deviceId: String
    let baseUrl: String
}

/// Result of `verifyOTP`. Existing users without two-step verification receive a Matrix session immediately;
/// brand-new users receive a `signupToken` to pass to `completeSignup` with a chosen username and display name;
/// returning users with two-step verification enabled receive a `pinChallengeToken` to redeem at
/// `verifyPinChallenge` together with their account PIN.
enum IdentityServiceVerifyOutcome: Equatable, Sendable {
    case existingUser(IdentityServiceMatrixSession)
    case newUser(signupToken: String)
    case pinRequired(challengeToken: String)
}

enum IdentityServiceError: Error, LocalizedError {
    case notConfigured
    case invalidURL
    case rateLimited
    case invalidOTP
    case invalidPin
    case pinLocked(retryAfterSeconds: Int?)
    case pinChangeCooldown(retryAfterSeconds: Int?)
    case pinChangeChallengeInvalid
    case pinChallengeExpired
    case invalidSignupToken
    case invalidUsername(String?)
    case usernameTaken
    case phoneAlreadyLinked
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
        case .pinChallengeExpired: "Your sign-in session expired. Please verify your phone again."
        case .invalidSignupToken: "Your signup session has expired. Please verify your phone again."
        case let .invalidUsername(message): message ?? "That username isn't allowed."
        case .usernameTaken: "That username is already taken. Please pick another."
        case .phoneAlreadyLinked: "This phone number is already linked to another account."
        case .invalidReauthToken: "Your verification expired. Please request a new code."
        case let .server(status, message): message ?? "Server error (\(status))."
        case let .transport(error): error.localizedDescription
        case let .decoding(error): "Could not parse the server response: \(error.localizedDescription)"
        }
    }
}

/// Minimal device metadata sent alongside an OTP verification request.
struct IdentityServiceDeviceInfo: Encodable, Sendable {
    let name: String?
    let platform: String?
    let appVersion: String?

    static var current: IdentityServiceDeviceInfo {
        let device = ProcessInfo.processInfo
        let bundle = Bundle.main
        let appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        #if os(iOS)
        let platform = "iOS"
        #elseif os(macOS)
        let platform = "macOS"
        #else
        let platform = "unknown"
        #endif
        return IdentityServiceDeviceInfo(name: device.hostName,
                                         platform: platform,
                                         appVersion: appVersion)
    }
}

@MainActor
protocol IdentityServiceClientProtocol {
    func sendOTP(phone: String, language: String?) async throws
    func verifyOTP(phone: String,
                   code: String,
                   pin: String?,
                   device: IdentityServiceDeviceInfo?) async throws -> IdentityServiceVerifyOutcome
    func completeSignup(signupToken: String,
                        username: String,
                        displayName: String,
                        pin: String?,
                        device: IdentityServiceDeviceInfo?) async throws -> IdentityServiceMatrixSession
    func verifyPinChallenge(pinChallengeToken: String,
                            pin: String,
                            device: IdentityServiceDeviceInfo?) async throws -> IdentityServiceMatrixSession
    func checkUsernameAvailability(_ username: String) async throws -> UsernameAvailability
    func startAccountReauth(accessToken: String, language: String?) async throws
    func verifyAccountReauth(accessToken: String, code: String) async throws -> String
    func deactivateAccount(accessToken: String, reauthToken: String, eraseData: Bool) async throws
    func resetIdentityCredentials(accessToken: String, reauthToken: String) async throws -> IdentityResetCredentials
    func pinStatus(accessToken: String) async throws -> Bool
    func setInitialPin(accessToken: String, userId: String, newPin: String) async throws
    func startPinChange(accessToken: String, phone: String, currentPin: String) async throws -> String
    func completePinChange(accessToken: String, challengeId: String, otpCode: String, newPin: String) async throws
}

/// Ephemeral credentials minted by the identity-service for the Matrix
/// `m.login.password` UIA stage during `client.resetIdentity()`.
struct IdentityResetCredentials: Equatable, Sendable {
    let userId: String
    let password: String
}

/// Result of a real-time `/signup/check-username` query.
enum UsernameAvailability: Equatable, Sendable {
    case available
    case taken
    case invalid(reason: String?)
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

    /// Convenience initializer using `Secrets.identityServiceBaseURL`.
    convenience init?() {
        guard let raw = Secrets.identityServiceBaseURL, let url = URL(string: raw) else { return nil }
        self.init(baseURL: url)
    }

    // MARK: - Public

    func sendOTP(phone: String, language: String?) async throws {
        struct Body: Encodable {
            let phone: String
            let language: String?
        }
        try await postExpectingEmpty(path: "/otp/send", body: Body(phone: phone, language: language))
    }

    func verifyOTP(phone: String,
                   code: String,
                   pin: String?,
                   device: IdentityServiceDeviceInfo?) async throws -> IdentityServiceVerifyOutcome {
        struct Body: Encodable {
            let phone: String
            let code: String
            let pin: String?
            let device: IdentityServiceDeviceInfo?
        }
        let body = Body(phone: phone, code: code, pin: pin, device: device)
        let response: VerifyResponse = try await post(path: "/otp/verify", body: body)
        if response.isNewUser == true, let token = response.signupToken {
            return .newUser(signupToken: token)
        }
        if response.pinRequired == true, let challenge = response.pinChallengeToken {
            return .pinRequired(challengeToken: challenge)
        }
        guard let accessToken = response.accessToken,
              let userId = response.userId,
              let deviceId = response.deviceId,
              let baseUrl = response.baseUrl else {
            throw IdentityServiceError.server(status: 200, message: "Malformed verify response from server.")
        }
        return .existingUser(IdentityServiceMatrixSession(accessToken: accessToken,
                                                          userId: userId,
                                                          deviceId: deviceId,
                                                          baseUrl: baseUrl))
    }

    func completeSignup(signupToken: String,
                        username: String,
                        displayName: String,
                        pin: String?,
                        device: IdentityServiceDeviceInfo?) async throws -> IdentityServiceMatrixSession {
        struct Body: Encodable {
            let signupToken: String
            let username: String
            let displayName: String
            let pin: String?
            let device: IdentityServiceDeviceInfo?
        }
        let body = Body(signupToken: signupToken,
                        username: username,
                        displayName: displayName,
                        pin: pin,
                        device: device)
        let response: VerifyResponse = try await post(path: "/signup/complete", body: body)
        guard let accessToken = response.accessToken,
              let userId = response.userId,
              let deviceId = response.deviceId,
              let baseUrl = response.baseUrl else {
            throw IdentityServiceError.server(status: 200, message: "Malformed signup response from server.")
        }
        return IdentityServiceMatrixSession(accessToken: accessToken,
                                            userId: userId,
                                            deviceId: deviceId,
                                            baseUrl: baseUrl)
    }

    func verifyPinChallenge(pinChallengeToken: String,
                            pin: String,
                            device: IdentityServiceDeviceInfo?) async throws -> IdentityServiceMatrixSession {
        struct Body: Encodable {
            let pinChallengeToken: String
            let pin: String
            let device: IdentityServiceDeviceInfo?
        }
        let body = Body(pinChallengeToken: pinChallengeToken, pin: pin, device: device)
        let response: VerifyResponse = try await post(path: "/signin/verify-pin", body: body)
        guard let accessToken = response.accessToken,
              let userId = response.userId,
              let deviceId = response.deviceId,
              let baseUrl = response.baseUrl else {
            throw IdentityServiceError.server(status: 200, message: "Malformed verify-pin response from server.")
        }
        return IdentityServiceMatrixSession(accessToken: accessToken,
                                            userId: userId,
                                            deviceId: deviceId,
                                            baseUrl: baseUrl)
    }

    func checkUsernameAvailability(_ username: String) async throws -> UsernameAvailability {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .invalid(reason: nil) }
        guard var components = URLComponents(url: baseURL.appendingPathComponent("/signup/check-username"),
                                             resolvingAgainstBaseURL: false) else {
            throw IdentityServiceError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "username", value: trimmed)]
        guard let url = components.url else { throw IdentityServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

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
        case 200:
            struct Body: Decodable { let available: Bool }
            do {
                let parsed = try decoder.decode(Body.self, from: data)
                return parsed.available ? .available : .taken
            } catch {
                throw IdentityServiceError.decoding(error)
            }
        case 400:
            let body = try? decoder.decode(ErrorBody.self, from: data)
            return .invalid(reason: body?.message)
        default:
            throw IdentityServiceError.server(status: httpResponse.statusCode, message: nil)
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

    private struct VerifyResponse: Decodable {
        let accessToken: String?
        let userId: String?
        let deviceId: String?
        let baseUrl: String?
        let isNewUser: Bool?
        let signupToken: String?
        let pinRequired: Bool?
        let pinChallengeToken: String?
    }

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

    private func post<RequestBody: Encodable, ResponseBody: Decodable>(path: String, body: RequestBody) async throws -> ResponseBody {
        let (data, _) = try await sendRequest(path: path, body: body, expectsBody: true)
        do {
            return try decoder.decode(ResponseBody.self, from: data)
        } catch {
            throw IdentityServiceError.decoding(error)
        }
    }

    private func postExpectingEmpty(path: String, body: some Encodable) async throws {
        _ = try await sendRequest(path: path, body: body, expectsBody: false)
    }

    private func sendRequest(path: String, body: some Encodable, expectsBody: Bool) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw IdentityServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
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
            if errorBody?.code == "invalid_username" {
                throw IdentityServiceError.invalidUsername(errorBody?.message)
            }
            if errorBody?.code == "invalid_otp" {
                throw IdentityServiceError.invalidOTP
            }
            if errorBody?.code == "invalid_pin" {
                throw IdentityServiceError.invalidPin
            }
            throw IdentityServiceError.server(status: 400, message: errorBody?.message ?? errorBody?.error)
        case 401:
            let errorBody = try? decoder.decode(ErrorBody.self, from: data)
            if errorBody?.code == "invalid_signup_token" {
                throw IdentityServiceError.invalidSignupToken
            }
            if errorBody?.code == "invalid_pin_challenge" {
                throw IdentityServiceError.pinChallengeExpired
            }
            throw IdentityServiceError.invalidOTP
        case 403:
            throw IdentityServiceError.invalidPin
        case 409:
            let errorBody = try? decoder.decode(ErrorBody.self, from: data)
            if errorBody?.code == "username_taken" {
                throw IdentityServiceError.usernameTaken
            }
            if errorBody?.code == "phone_already_linked" {
                throw IdentityServiceError.phoneAlreadyLinked
            }
            throw IdentityServiceError.server(status: 409, message: errorBody?.message ?? errorBody?.error)
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
}
