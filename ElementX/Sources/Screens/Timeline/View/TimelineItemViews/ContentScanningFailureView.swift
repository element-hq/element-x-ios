//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// The placeholder shown in place of a media item when the content scanner wasn't able to
/// validate it. Preview and download of the content are disabled.
///
/// This view only renders the failure title and message - the critical background is applied
/// to the whole message bubble by `TimelineItemBubbledStylerView`, so that any caption and
/// reply preview are included in the critical area too.
struct ContentScanningFailureView: View {
    let failure: ContentScanningFailure
    
    var body: some View {
        HStack(spacing: 8) {
            CompoundIcon(\.error, size: .medium, relativeTo: .compound.bodyMDSemibold)
                .foregroundStyle(.compound.iconCriticalPrimary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.compound.bodyMDSemibold)
                    .foregroundStyle(.compound.textCriticalPrimary)
                
                Text(message)
                    .font(.compound.bodySM)
                    .foregroundStyle(.compound.textSecondary)
            }
        }
    }
    
    private var title: String {
        switch failure {
        case .notSafe: L10n.commonContentScannerUnsafeTitle
        case .notFound: L10n.commonContentScannerNotFoundTitle
        }
    }
    
    private var message: String {
        switch failure {
        case .notSafe: L10n.commonContentScannerUnsafeMessage
        case .notFound: L10n.commonContentScannerNotFound
        }
    }
}

// MARK: - Previews

struct ContentScanningFailureView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 16) {
            ContentScanningFailureView(failure: .notSafe)
            ContentScanningFailureView(failure: .notFound)
        }
        .frame(width: 260)
        .padding()
    }
}
