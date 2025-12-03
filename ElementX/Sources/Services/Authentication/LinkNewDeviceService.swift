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
    typealias GenerateProgressPublisher = CurrentValuePublisher<GrantGeneratedQrLoginProgress, QRCodeLoginError>
    typealias ScanProgressPublisher = CurrentValuePublisher<GrantQrLoginProgress, QRCodeLoginError>
    
    private let grantLoginHandler: GrantLoginWithQrCodeHandlerProtocol
    
    init(handler: GrantLoginWithQrCodeHandlerProtocol) {
        grantLoginHandler = handler
    }
    
    func generateQRCode() -> GenerateProgressPublisher {
        let progressSubject = CurrentValueSubject<GrantGeneratedQrLoginProgress, QRCodeLoginError>(.starting)
        let listener = SDKListener { progressSubject.send($0) }
        
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
        let progressSubject = CurrentValueSubject<GrantQrLoginProgress, QRCodeLoginError>(.starting)
        let listener = SDKListener { progressSubject.send($0) }
        
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
