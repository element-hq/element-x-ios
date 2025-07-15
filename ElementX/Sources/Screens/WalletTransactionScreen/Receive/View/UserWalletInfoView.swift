//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI
import UIKit
import QRCode

struct UserWalletInfoView: View {
    @ObservedObject var context: ReceiveTransactionViewModel.Context
    
    var body: some View {
        VStack {
            Spacer()
            
            if let user = context.viewState.currentUser, let address = user.publicWalletAddress {
                VStack {
                    Text(user.displayName)
                        .font(.compound.headingSMSemibold)
                        .foregroundStyle(.compound.textPrimary)
                    
                    if let formattedAddress = displayFormattedAddress(address) {
                        Text(formattedAddress)
                            .font(.zero.bodyMD)
                            .foregroundStyle(.compound.textSecondary)
                    }
                    
                    QRCodeView(address: address)
                        .padding(.vertical, 12)
                    
                    Text("Supported Networks")
                        .font(.zero.bodySM)
                        .foregroundStyle(.compound.textSecondary)
                    
                    Image(asset: Asset.Images.iconZChain)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                CopyButton(onTap : {
                    context.send(viewAction: .copyAddress)
                })
                
                //                ShareButton(onTap: {
                //
                //                })
            }
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.zero.bgCanvasDefault.ignoresSafeArea())
        .padding()
    }
}

struct QRCodeView: View {
    let address: String
    let targetLogoFraction: CGFloat = 0.4  // 40% of QR dimension
    
    private var fgColor: CGColor { UIColor(.black).cgColor }
    private var bgColor: CGColor { UIColor(.zero.bgAccentRest).cgColor }
    
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
    
    var body: some View {
        QRCodeViewUI(
            content: address,
            foregroundColor: fgColor,
            backgroundColor: bgColor,
            pixelStyle: QRCode.PixelShape.Circle(),
            eyeStyle: QRCode.EyeShape.Circle(),
            pupilStyle: QRCode.PupilShape.Circle(),
            logoTemplate: logoTemplate,
            additionalQuietZonePixels: 1,
            backgroundFractionalCornerRadius: 4
        )
        .frame(width: 175, height: 175)
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

struct CopyButton: View {
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            Button {
                onTap()
            } label: {
                Image(asset: Asset.Images.iconCopy)
                    .renderingMode(.template)
                    .foregroundStyle(.compound.iconSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.compound.iconSecondary, lineWidth: 1)
            )
            
            Text("Copy")
                .font(.zero.bodySM)
                .foregroundStyle(.compound.iconSecondary)
                .padding(.vertical, 1)
        }
    }
}

struct ShareButton: View {
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            Button {
                onTap()
            } label: {
                CompoundIcon(\.share)
                    .foregroundStyle(.compound.iconSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.compound.iconSecondary, lineWidth: 1)
            )
            
            Text("Share")
                .font(.zero.bodySM)
                .foregroundStyle(.compound.iconSecondary)
                .padding(.vertical, 1)
        }
    }
}
