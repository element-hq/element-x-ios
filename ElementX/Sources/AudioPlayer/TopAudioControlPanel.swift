//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
//

import SwiftUI
import Compound

struct TopAudioControlPanel: View {
    let player = AudioPlaybackService.shared
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                CompoundIcon(\.audio)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.tint)
                    .background(.gray.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(player.title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                    
                    Text(player.state.displayText)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    player.togglePlayPause()
                } label: {
                    Image(systemName: player.state == .playing ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 48, height: 48)
                        .foregroundStyle(.tint)
                }
            }
            
            ProgressView(value: player.progress)
                .progressViewStyle(.linear)
                .tint(.blue)
            
            HStack {
                Text(formatTime(player.currentTime))
                Spacer()
                Text(formatTime(player.duration))
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            
            // Кнопки скорости (как в Element X)
            HStack(spacing: 12) {
                ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { speed in
                    Button {
                        player.setSpeed(speed)
                    } label: {
                        Text("\(speed, specifier: "%.1f")×")
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                player.playbackSpeed == speed ?
                                Color.accentColor.opacity(0.25) :
                                Color.gray.opacity(0.12)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        guard interval.isFinite, interval >= 0 else { return "0:00" }
        let mins = Int(interval) / 60
        let secs = Int(interval) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

#Preview {
    TopAudioControlPanel()
        .previewLayout(.sizeThatFits)
        .padding()
}
