//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct EstimatedWaveform: Equatable, Hashable {
    static let dataRange: ClosedRange<UInt16> = 0...1024
    let data: [UInt16]
}

extension EstimatedWaveform {
    /// Maps the `data` array to Float values in the range 0...1 respecting the `Self.dataRange` limits.
    /// Up to `maxSamplesCount` will be returned in the output array
    func normalisedData(maxSamplesCount: Int) -> [Float] {
        guard maxSamplesCount > 0 else {
            return []
        }

        // Filter the data to keep only the expected number of samples
        let result: [UInt16]
        if data.count > maxSamplesCount {
            result = (0..<maxSamplesCount)
                .map { index in
                    let targetIndex = Int((Double(index) * (Double(data.count) / Double(maxSamplesCount))).rounded())
                    return UInt16(data[targetIndex])
                }
        } else {
            result = data
        }

        // Normalize the sample in the allowed range
        return result.map { Float($0) / Float(Self.dataRange.upperBound) }
    }
}

extension EstimatedWaveform {
    static let mockWaveform = EstimatedWaveform(data: [0, 0, 0, 3, 3, 127, 400, 266, 126, 122, 373, 251, 45, 112,
                                                       334, 205, 99, 138, 397, 354, 125, 361, 199, 51,
                                                       294, 131, 19, 2, 3, 3, 1, 2, 0, 0,
                                                       0, 0])
}

struct EstimatedWaveformView: View {
    var lineWidth: CGFloat = 2
    var linePadding: CGFloat = 2
    var waveform: EstimatedWaveform
    var progress: CGFloat = 0.0
    
    @State private var normalizedWaveformData: [Float] = []
    
    var body: some View {
        GeometryReader { geometry in
            WaveformShape(lineWidth: lineWidth,
                          linePadding: linePadding,
                          waveformData: normalizedWaveformData)
                .stroke(Color.compound.iconSecondary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .progressMask(progress: progress)
                .preference(key: ViewSizeKey.self, value: geometry.size)
        }
        .onPreferenceChange(ViewSizeKey.self) { size in
            buildNormalizedWaveformData(size: size)
        }
    }
    
    private func buildNormalizedWaveformData(size: CGSize) {
        let count = Int(size.width / (lineWidth + linePadding))
        // Rebuild the normalized waveform data only if the count has changed
        if normalizedWaveformData.count == count {
            return
        }
        normalizedWaveformData = waveform.normalisedData(maxSamplesCount: count)
    }
}

private struct ViewSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private struct WaveformShape: Shape {
    let lineWidth: CGFloat
    let linePadding: CGFloat
    let waveformData: [Float]
    var minimumGraphAmplitude: CGFloat = 1.0
    
    func path(in rect: CGRect) -> Path {
        let width = rect.size.width
        let height = rect.size.height
        let centerY = rect.size.height / 2
        var xOffset: CGFloat = lineWidth / 2
        var index = 0
        
        var path = Path()
        while xOffset <= width {
            let sample = CGFloat(index >= waveformData.count ? 0 : waveformData[index])
            let drawingAmplitude = max(minimumGraphAmplitude, sample * (height - 2))
            
            path.move(to: CGPoint(x: xOffset, y: centerY - drawingAmplitude / 2))
            path.addLine(to: CGPoint(x: xOffset, y: centerY + drawingAmplitude / 2))
            xOffset += lineWidth + linePadding
            index += 1
        }
        
        return path
    }
}

struct EstimatedWaveformView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        // Wrap the WaveformView in a VStack otherwise the preview test will fail (because of Prefire / GeometryReader)
        VStack(spacing: 0) {
            EstimatedWaveformView(waveform: EstimatedWaveform.mockWaveform, progress: 0.5)
                .frame(width: 140, height: 50)
        }
    }
}
