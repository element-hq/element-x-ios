//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import UIKit
import QRCode

struct UserWalletQRCode : View {
    let walletAddress: String
    let onQRCodeGenerated: (UIImage?) -> Void
    
    private let targetLogoFraction: CGFloat = 0.4  // 40% of QR dimension
        
    private var fgColor: CGColor { UIColor.black.cgColor }
    private var bgColor: CGColor { UIColor(.zero.bgAccentRest).cgColor }
    
    var body: some View {
        QRCodeDocumentUIView(document: qrDocument)
            .frame(width: 175, height: 175)
            .task {
                if let cgImage = qrDocument.cgImage(dimension: 1024) {
                    let qrImage = UIImage(cgImage: cgImage)
                    onQRCodeGenerated(qrImage)
                }
            }
    }
    
    private var qrDocument: QRCode.Document {
        let doc = QRCode.Document(utf8String: walletAddress, errorCorrection: .high)
        doc.design.backgroundColor(bgColor)
        doc.design.foregroundColor(fgColor)
        doc.design.shape.eye = QRCode.EyeShape.Circle()
        doc.design.shape.pupil = QRCode.PupilShape.Circle()
        doc.design.shape.onPixels = QRCode.PixelShape.Circle()
        doc.design.additionalQuietZonePixels = 1
        doc.design.style.backgroundFractionalCornerRadius = 4
        if let logo = logoTemplate {
            doc.logoTemplate = logo
        }
        return doc
    }
    
    private var logoTemplate: QRCode.LogoTemplate? {
        guard let uiImage = UIImage(named: Asset.Images.zeroLogoMark.name),
              let tinted = tintedCGImage(from: uiImage, tintColor: .black) else {
            return nil
        }
        
        let inset: CGFloat = 4
        let size = targetLogoFraction
        let rect = CGRect(x: (1 - size)/2,
                          y: (1 - size)/2,
                          width: size,
                          height: size)
        let path = CGPath(ellipseIn: rect, transform: nil)
        
        return QRCode.LogoTemplate(
            image: tinted,
            path: path,
            inset: inset
        )
    }
    
    private func tintedCGImage(from image: UIImage, tintColor: UIColor) -> CGImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        tintColor.setFill()
        let rect = CGRect(origin: .zero, size: image.size)
        image.withRenderingMode(.alwaysTemplate).draw(in: rect)
        
        return UIGraphicsGetImageFromCurrentImageContext()?.cgImage
    }
}
