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
        let stride = max(1, Int(data.count / count))
        let data = data.striding(by: stride)
        let max = data.max().flatMap { Float($0) } ?? 0
        return data.map { Float($0) / max }
    }
}

extension Waveform {
    static let mockWaveform = Waveform(data: [0, 0, 0, 3, 3, 127, 400, 266, 126, 122, 373, 251, 45, 112,
                                              334, 205, 99, 138, 397, 354, 125, 361, 199, 51,
                                              294, 131, 19, 2, 3, 3, 1, 2, 0, 0,
                                              0, 0])
}

struct WaveformView: View {
    let lineWidth: CGFloat = 2
    let linePadding: CGFloat = 2
    var waveform: Waveform
    let minimumGraphAmplitude: CGFloat = 1
    var progress: CGFloat = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.compound.iconQuaternary)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                Rectangle().fill(Color.compound.iconSecondary)
                    .frame(width: max(0.0, geometry.size.width * progress), height: geometry.size.height)
            }
            .mask(alignment: .leading) {
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let centerY = geometry.size.height / 2
                    let visibleSamplesCount = Int(width / (lineWidth + linePadding))
                    let normalisedData = waveform.normalisedData(count: visibleSamplesCount)
                    var xOffset: CGFloat = lineWidth / 2
                    var index = 0
                    
                    while xOffset < width - lineWidth {
                        let sample = CGFloat(index >= normalisedData.count ? 0 : normalisedData[index])
                        let drawingAmplitude = max(minimumGraphAmplitude, sample * height)

                        path.move(to: CGPoint(x: xOffset, y: centerY - drawingAmplitude / 2))
                        path.addLine(to: CGPoint(x: xOffset, y: centerY + drawingAmplitude / 2))
                        xOffset += lineWidth + linePadding
                        index += 1
                    }
                }
                .stroke(Color.compound.iconSecondary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }
    }
}

struct WaveformView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        WaveformView(waveform: Waveform.mockWaveform)
            .frame(width: 140, height: 50)
    }
}
