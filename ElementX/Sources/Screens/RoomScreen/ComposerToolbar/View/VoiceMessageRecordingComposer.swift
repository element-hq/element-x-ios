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
    @State private var currentTranscript = ""
    @State private var showTranscript = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Transcript popup box that appears above the recording view
            if showTranscript, !currentTranscript.isEmpty {
                TranscriptPopupView(transcript: currentTranscript)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1) // Ensure it appears above the recording view
                    .offset(y: -2) // Position it slightly above the recording view
            }
            
            // Fixed height container for the recording view
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
                .fixedSize(horizontal: false, vertical: true) // Keep vertical size fixed
        }
        .animation(.easeInOut(duration: 0.2), value: showTranscript && !currentTranscript.isEmpty)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("VoiceMessageTranscriptUpdate"))) { notification in
            if let transcript = notification.object as? String {
                currentTranscript = transcript
                showTranscript = true
            }
        }
    }
}

struct TranscriptPopupView: View {
    var transcript: String
    
    var body: some View {
        ScrollView {
            Text(transcript)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
        .frame(maxHeight: 120) // Fixed maximum height
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.compound.bgCanvasDefault)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 12)
    }
}

struct VoiceMessageRecordingComposer_Previews: PreviewProvider, TestablePreview {
    static let recorderState = AudioRecorderState()
    
    static var previews: some View {
        VoiceMessageRecordingComposer(recorderState: recorderState)
            .fixedSize(horizontal: false, vertical: true)
    }
}
