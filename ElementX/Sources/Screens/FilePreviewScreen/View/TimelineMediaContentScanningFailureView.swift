//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// Shown fullscreen in place of the media preview when the media failed content scanning.
struct TimelineMediaContentScanningFailureView: View {
    let failure: ContentScanningFailure
    
    var body: some View {
        VStack(spacing: 16) {
            BigIcon(icon: \.errorSolid, style: .alertSolid)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.compound.bodyLGSemibold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }
    
    private var title: String {
        switch failure {
        case .notSafe: L10n.contentScannerUnsafeTitle
        case .notFound: L10n.contentScannerNotFoundTitle
        }
    }
    
    private var message: String {
        switch failure {
        case .notSafe: L10n.contentScannerUnsafeMessage
        case .notFound: L10n.contentScannerNotFound
        }
    }
}

// MARK: - Previews

struct TimelineMediaContentScanningFailureView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 48) {
            TimelineMediaContentScanningFailureView(failure: .notSafe)
            TimelineMediaContentScanningFailureView(failure: .notFound)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.compound.bgCanvasDefault)
        .preferredColorScheme(.dark) // The preview controller forces a dark appearance.
    }
}
