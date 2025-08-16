//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct TransactionInProgressView: View {
    var size: CGFloat = 60
    var color: Color = .blue
    
    var message: String?
    var subMessage: String = "Just a moment..."
    
    var backgroundColor: Color = Color.zero.bgCanvasDefault
    
    @State private var rotation: Angle = .degrees(0)
    @State private var animateWave = false
    
    var body: some View {
        VStack {
            ZStack {
                // Continuous pulse waves
                ForEach(0..<3) { i in
                    WaveCircle(size: size * 0.6, color: color, delay: Double(i) * 0.4)
                }
                
                Circle()
                    .fill(color)
                    .frame(width: (size / 5), height: (size / 5))
                
                // Indeterminate spinning arc
                CircleProgressRing(size: size, color: color)
                    .rotationEffect(rotation)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                            rotation = .degrees(360)
                        }
                    }
            }
            .frame(width: size, height: size)
            
            if let message = message {
                VStack {
                    Text(message)
                        .font(.compound.bodyLGSemibold)
                        .foregroundColor(color)
                    
                    Text(subMessage)
                        .font(.compound.bodyMD)
                        .foregroundColor(.compound.textSecondary)
                }
                .padding(.vertical, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor.ignoresSafeArea())
        .padding()
    }
}

private struct WaveCircle: View {
    var size: CGFloat
    var color: Color
    var delay: Double
    
    @State private var animate = false
    
    var body: some View {
        Circle()
            .fill(color.opacity(0.2))
            .frame(width: size, height: size)
            .scaleEffect(animate ? 2.2 : 0.8)
            .opacity(animate ? 0.0 : 0.9)
            .animation(
                Animation.easeOut(duration: 2.0)
                    .repeatForever(autoreverses: false)
                    .delay(delay),
                value: animate
            )
            .onAppear {
                animate = true
            }
    }
}

private struct CircleProgressRing: View {
    var size: CGFloat
    var color: Color
    
    var body: some View {
        Circle()
            .trim(from: 0.0, to: 0.7)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: 4,
                    lineCap: .round
                )
            )
            .frame(width: size, height: size)
    }
}
