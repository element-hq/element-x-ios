//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// The grid item shown in place of a media item whilst it's being scanned by the content scanner.
struct ScanningMediaEventsTimelineView: View {
    var body: some View {
        Color.compound.bgSubtleSecondary
            .opacity(0.3)
            .aspectRatio(1, contentMode: .fill)
            .overlay {
                ProgressView()
            }
            .accessibilityLabel(L10n.commonLoading)
    }
}

/// The grid item shown in place of a media item that failed content scanning.
struct UnsafeMediaEventsTimelineView: View {
    let failure: ContentScanningFailure
    
    var body: some View {
        Color.compound.bgCriticalSubtle
            .aspectRatio(1, contentMode: .fill)
            .overlay {
                CompoundIcon(\.error, size: .medium, relativeTo: .compound.headingLG)
                    .foregroundStyle(.compound.iconCriticalPrimary)
            }
            .accessibilityLabel(accessibilityLabel)
    }
    
    private var accessibilityLabel: String {
        switch failure {
        case .notSafe: L10n.contentScannerUnsafeTitle
        case .notFound: L10n.contentScannerNotFoundTitle
        }
    }
}

// MARK: - Previews

struct ScanStateMediaEventsTimelineViews_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        HStack(spacing: 16) {
            ScanningMediaEventsTimelineView()
                .frame(width: 100, height: 100)
            
            UnsafeMediaEventsTimelineView(failure: .notSafe)
                .frame(width: 100, height: 100)
        }
        .padding()
    }
}
