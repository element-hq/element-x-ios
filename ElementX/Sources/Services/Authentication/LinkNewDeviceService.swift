//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

class LinkNewDeviceService {
    typealias GenerateProgressPublisher = CurrentValuePublisher<GenerateProgress, QRCodeLoginError>
    typealias ScanProgressPublisher = CurrentValuePublisher<ScanProgress, QRCodeLoginError>
    
    enum GenerateProgress {
        case starting
        case qrReady(QrCodeData)
        case qrScanned(CheckCodeSenderProtocol)
        case waitingForAuthorisation(verificationURI: String)
        case syncingSecrets
        case done
    }

    enum ScanProgress {
        case starting
        case establishingSecureChannel(checkCode: UInt8, checkCodeString: String)
        case waitingForAuth(verificationURI: String)
        case syncingSecrets
        case done
    }
    
    private let grantLoginHandler: GrantLoginWithQrCodeHandlerProtocol
    
    init(handler: GrantLoginWithQrCodeHandlerProtocol) {
        grantLoginHandler = handler
    }
    
    func generateQRCode() -> GenerateProgressPublisher {
        let progressSubject = CurrentValueSubject<GenerateProgress, QRCodeLoginError>(.starting)
        let listener = SDKListener { progressSubject.send(.init(rustProgress: $0)) }
        
        Task {
            do {
                // TODO: we need a way to cancel the in progress grant if the user hit the cancel button
                try await grantLoginHandler.generate(progressListener: listener) // The success state is handled by the listener.
            } catch let error as HumanQrGrantLoginError {
                MXLog.error("QR code reciprocate error: \(error)")
                progressSubject.send(completion: .failure(.init(rustError: error)))
            } catch {
                MXLog.error("QR code reciprocate unknown error: \(error)")
                progressSubject.send(completion: .failure(.unknown))
            }
        }
        
        return progressSubject.asCurrentValuePublisher()
    }
    
    func scanQRCode(_ scannedQRData: Data) -> ScanProgressPublisher {
        let progressSubject = CurrentValueSubject<ScanProgress, QRCodeLoginError>(.starting)
        let listener = SDKListener { progressSubject.send(.init(rustProgress: $0)) }
        
        let qrCodeData: QrCodeData
        do {
            qrCodeData = try QrCodeData.fromBytes(bytes: scannedQRData)
        } catch {
            MXLog.error("QR code decode error: \(error)")
            progressSubject.send(completion: .failure(.invalidQRCode))
            return progressSubject.asCurrentValuePublisher()
        }
        
        #warning("Check intent/server name here…")
        
        Task {
            do {
                // TODO: it would be nice to be able to cancel the grant at the SDK level if the user hits the cancel button
                try await grantLoginHandler.scan(qrCodeData: qrCodeData, progressListener: listener) // The success state is handled by the listener.
            } catch let error as HumanQrGrantLoginError {
                MXLog.error("QR code reciprocate error: \(error)")
                progressSubject.send(completion: .failure(.init(rustError: error)))
            } catch {
                MXLog.error("QR code reciprocate unknown error: \(error)")
                progressSubject.send(completion: .failure(.unknown))
            }
        }
        
        return progressSubject.asCurrentValuePublisher()
    }
}

extension LinkNewDeviceService.GenerateProgress: CustomStringConvertible {
    init(rustProgress: GrantGeneratedQrLoginProgress) {
        self = switch rustProgress {
        case .starting: .starting
        case .qrReady(let qrCode): .qrReady(qrCode)
        case .qrScanned(let checkCodeSender): .qrScanned(checkCodeSender)
        case .waitingForAuth(let verificationUri): .waitingForAuthorisation(verificationURI: verificationUri)
        case .syncingSecrets: .syncingSecrets
        case .done: .done
        }
    }
    
    var description: String {
        switch self {
        case .starting: "starting"
        case .qrReady: "qrReady"
        case .qrScanned: "qrScanned"
        case .waitingForAuthorisation: "waitingForAuthorisation"
        case .syncingSecrets: "syncingSecrets"
        case .done: "done"
        }
    }
}

extension LinkNewDeviceService.ScanProgress: CustomStringConvertible {
    init(rustProgress: GrantQrLoginProgress) {
        self = switch rustProgress {
        case .starting: .starting
        case .establishingSecureChannel(let checkCode, let checkCodeString): .establishingSecureChannel(checkCode: checkCode, checkCodeString: checkCodeString)
        case .waitingForAuth(let verificationUri): .waitingForAuth(verificationURI: verificationUri)
        case .syncingSecrets: .syncingSecrets
        case .done: .done
        }
    }
    
    var description: String {
        switch self {
        case .starting: "starting"
        case .establishingSecureChannel: "establishingSecureChannel"
        case .waitingForAuth: "waitingForAuth"
        case .syncingSecrets: "syncingSecrets"
        case .done: "done"
        }
    }
}

private extension QRCodeLoginError {
    init(rustError: HumanQrGrantLoginError) {
        self = switch rustError {
        case .InvalidCheckCode:
            .connectionInsecure
        case .UnsupportedProtocol:
            .linkingNotSupported
        case .Unknown, .NotFound, .MissingSecretsBackup, .DeviceIdAlreadyInUse, .UnableToCreateDevice:
            .unknown
        }
    }
}
