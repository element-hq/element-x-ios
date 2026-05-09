//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import Foundation
import SwiftUI

struct VoiceMessageRecordingComposer: View {
    @ObservedObject var recorderState: AudioRecorderState
    
    var body: some View {
        VoiceMessageRecordingView(recorderState: recorderState)
            .padding(.vertical, Compound.supportsGlass ? 14 : 8)
            .padding(.horizontal, Compound.supportsGlass ? 16 : 12)
            .background {
                RoundedRectangle(cornerRadius: Compound.supportsGlass ? 21 : 12)
                    .fill(.compound.bgSubtleSecondary)
            }
    }
}

// MARK: - Previews

struct VoiceMessageRecordingComposer_Previews: PreviewProvider, TestablePreview {
    static let recorderState = AudioRecorderState()
    
    static var previews: some View {
        VoiceMessageRecordingComposer(recorderState: recorderState)
            .fixedSize(horizontal: false, vertical: true)
    }
}
