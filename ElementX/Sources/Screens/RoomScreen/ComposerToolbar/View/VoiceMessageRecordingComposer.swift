//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import Foundation
import SwiftUI

struct VoiceMessageRecordingComposer: View {
    @ObservedObject var recorderState: AudioRecorderState
    
    var body: some View {
        VoiceMessageRecordingView(recorderState: recorderState)
            .padding(.vertical, 8.0)
            .padding(.horizontal, 12.0)
            .background {
                let roundedRectangle = RoundedRectangle(cornerRadius: 12)
                ZStack {
                    roundedRectangle
                        .fill(Color.compound.bgSubtleSecondary)
                }
            }
    }
}

struct VoiceMessageRecordingComposer_Previews: PreviewProvider, TestablePreview {
    static let recorderState = AudioRecorderState()
    
    static var previews: some View {
        VoiceMessageRecordingComposer(recorderState: recorderState)
            .fixedSize(horizontal: false, vertical: true)
    }
}
