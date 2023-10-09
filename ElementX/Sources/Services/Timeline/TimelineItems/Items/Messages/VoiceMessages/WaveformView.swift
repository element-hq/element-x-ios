//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

struct Waveform: Equatable, Hashable {
    let data: [UInt16]
}

extension Waveform {
    func normalisedData(count: Int) -> [Float] {
        guard count > 0 else {
            return []
        }
        // Filter the data to keep only the expected number of samples
        let originalCount = Double(data.count)
        let expectedCount = Double(count)
        var filteredData: [UInt16] = []
        if expectedCount < originalCount {
            for index in 0..<count {
                let targetIndex = (Double(index) * (originalCount / expectedCount)).rounded()
                filteredData.append(UInt16(data[Int(targetIndex)]))
            }
        } else {
            filteredData = data
        }
        // Normalize the sample
        let max = max(1.0, filteredData.max().flatMap { Float($0) } ?? 1.0)
        return filteredData.map { Float($0) / max }
    }
}

extension Waveform {
    static let mockWaveform = Waveform(data: [0, 0, 0, 3, 3, 127, 400, 266, 126, 122, 373, 251, 45, 112,
                                              334, 205, 99, 138, 397, 354, 125, 361, 199, 51,
                                              294, 131, 19, 2, 3, 3, 1, 2, 0, 0,
                                              0, 0])
}

struct WaveformView: View {
    var lineWidth: CGFloat = 2
    var linePadding: CGFloat = 2
    var waveform: Waveform
    private let minimumGraphAmplitude: CGFloat = 1
    var progress: CGFloat = 0.0
    var showCursor = false

    @State private var waveformPathSize: CGSize = .zero
    @State private var waveformPath: Path?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.compound.iconQuaternary)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                Rectangle().fill(Color.compound.iconSecondary)
                    .frame(width: max(0.0, geometry.size.width * progress), height: geometry.size.height)
            }
            .mask(alignment: .leading) {
                WaveformShape(lineWidth: lineWidth,
                              linePadding: linePadding,
                              waveform: waveform)
                    .stroke(Color.compound.iconSecondary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
            // Display a cursor
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1).fill(Color.compound.iconAccentTertiary)
                    .offset(CGSize(width: progress * geometry.size.width, height: 0.0))
                    .frame(width: lineWidth, height: geometry.size.height)
                    .opacity(showCursor ? 1 : 0)
            }
        }
    }
}

private struct WaveformShape: Shape {
    let lineWidth: CGFloat
    let linePadding: CGFloat
    let waveform: Waveform
    var minimumGraphAmplitude: CGFloat = 1.0
    
    func path(in rect: CGRect) -> Path {
        let width = rect.size.width
        let height = rect.size.height
        let centerY = rect.size.height / 2
        let visibleSamplesCount = Int(width / (lineWidth + linePadding))
        let normalisedData = waveform.normalisedData(count: visibleSamplesCount)
        var xOffset: CGFloat = lineWidth / 2
        var index = 0
        
        var path = Path()
        while xOffset <= width {
            let sample = CGFloat(index >= normalisedData.count ? 0 : normalisedData[index])
            let drawingAmplitude = max(minimumGraphAmplitude, sample * (height - 2))

            path.move(to: CGPoint(x: xOffset, y: centerY - drawingAmplitude / 2))
            path.addLine(to: CGPoint(x: xOffset, y: centerY + drawingAmplitude / 2))
            xOffset += lineWidth + linePadding
            index += 1
        }
        
        return path
    }
}

struct WaveformView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        WaveformView(waveform: Waveform.mockWaveform, progress: 0.5)
            .frame(width: 140, height: 50)
    }
}
