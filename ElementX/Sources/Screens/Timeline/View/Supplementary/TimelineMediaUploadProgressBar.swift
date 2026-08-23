//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// A thin bar along the bottom of a media bubble while the media is uploading, showing how far
/// the upload has got. Nothing once it's sent (or when there's no progress to show).
struct TimelineMediaUploadProgressBar: View {
    let progress: Double?
    
    var body: some View {
        if let progress {
            ProgressView(value: progress)
                .tint(.compound.iconOnSolidPrimary)
                .background(.compound.bgCanvasDefault.opacity(0.4), in: Capsule())
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .accessibilityLabel(L10n.commonSending)
        }
    }
}

struct TimelineMediaUploadProgressBar_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        Rectangle()
            .fill(.gray)
            .frame(width: 240, height: 160)
            .overlay(alignment: .bottom) { TimelineMediaUploadProgressBar(progress: 0.4) }
    }
}
