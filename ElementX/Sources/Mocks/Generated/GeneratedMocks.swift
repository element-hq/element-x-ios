// Generated using Sourcery 2.0.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

import Combine
import MatrixRustSDK























class SessionVerificationControllerProxyProtocolMock: SessionVerificationControllerProxyProtocol {


    var callbacks: PassthroughSubject<SessionVerificationControllerProxyCallback, Never> {
        get { return underlyingCallbacks }
        set(value) { underlyingCallbacks = value }
    }
    var underlyingCallbacks: PassthroughSubject<SessionVerificationControllerProxyCallback, Never>!
    var isVerified: Bool {
        get { return underlyingIsVerified }
        set(value) { underlyingIsVerified = value }
    }
    var underlyingIsVerified: Bool!


    // MARK: - requestVerification

    var requestVerificationCallsCount = 0
    var requestVerificationCalled: Bool {
        return requestVerificationCallsCount > 0
    }
    var requestVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var requestVerificationClosure: (() async -> Result<Void, SessionVerificationControllerProxyError>)?

    func requestVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        requestVerificationCallsCount += 1
        if let requestVerificationClosure = requestVerificationClosure {
            return await requestVerificationClosure()
        } else {
            return requestVerificationReturnValue
        }
    }

    // MARK: - startSasVerification

    var startSasVerificationCallsCount = 0
    var startSasVerificationCalled: Bool {
        return startSasVerificationCallsCount > 0
    }
    var startSasVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var startSasVerificationClosure: (() async -> Result<Void, SessionVerificationControllerProxyError>)?

    func startSasVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        startSasVerificationCallsCount += 1
        if let startSasVerificationClosure = startSasVerificationClosure {
            return await startSasVerificationClosure()
        } else {
            return startSasVerificationReturnValue
        }
    }

    // MARK: - approveVerification

    var approveVerificationCallsCount = 0
    var approveVerificationCalled: Bool {
        return approveVerificationCallsCount > 0
    }
    var approveVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var approveVerificationClosure: (() async -> Result<Void, SessionVerificationControllerProxyError>)?

    func approveVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        approveVerificationCallsCount += 1
        if let approveVerificationClosure = approveVerificationClosure {
            return await approveVerificationClosure()
        } else {
            return approveVerificationReturnValue
        }
    }

    // MARK: - declineVerification

    var declineVerificationCallsCount = 0
    var declineVerificationCalled: Bool {
        return declineVerificationCallsCount > 0
    }
    var declineVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var declineVerificationClosure: (() async -> Result<Void, SessionVerificationControllerProxyError>)?

    func declineVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        declineVerificationCallsCount += 1
        if let declineVerificationClosure = declineVerificationClosure {
            return await declineVerificationClosure()
        } else {
            return declineVerificationReturnValue
        }
    }

    // MARK: - cancelVerification

    var cancelVerificationCallsCount = 0
    var cancelVerificationCalled: Bool {
        return cancelVerificationCallsCount > 0
    }
    var cancelVerificationReturnValue: Result<Void, SessionVerificationControllerProxyError>!
    var cancelVerificationClosure: (() async -> Result<Void, SessionVerificationControllerProxyError>)?

    func cancelVerification() async -> Result<Void, SessionVerificationControllerProxyError> {
        cancelVerificationCallsCount += 1
        if let cancelVerificationClosure = cancelVerificationClosure {
            return await cancelVerificationClosure()
        } else {
            return cancelVerificationReturnValue
        }
    }

}

// swiftlint:enable all
