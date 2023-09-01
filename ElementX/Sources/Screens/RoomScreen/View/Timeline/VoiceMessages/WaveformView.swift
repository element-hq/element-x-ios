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

struct Waveform {
    let data: [Float]
}

extension Waveform {
    static let maximum: Float = 400
    var normalisedData: [Float] {
        data.map { $0 / Self.maximum }
    }
}

extension Waveform {
    static let mockWaveform = Waveform(data: [0, 0, 0, 3, 3, 127, 400, 266, 126, 122, 373, 251, 45, 112,
                                              334, 205, 99, 138, 397, 354, 125, 361, 199, 51,
                                              294, 131, 19, 2, 3, 3, 1, 2, 0, 0,
                                              0, 0])
}

struct WaveformView: View {
    var waveform: Waveform
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let centerY = geometry.size.height / 2
                let normalisedData = waveform.normalisedData
                for i in 0..<waveform.data.count {
                    let x = (geometry.size.width / CGFloat(waveform.data.count)) * CGFloat(i)
                    let height = geometry.size.height * CGFloat(normalisedData[i])
                    path.move(to: CGPoint(x: x, y: centerY - (height / 2)))
                    path.addLine(to: CGPoint(x: CGFloat(x), y: centerY + (height / 2)))
                }
            }
            .stroke(Color.compound.iconQuaternary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }
}

struct WaveformView_Previews: PreviewProvider {
    static var previews: some View {
        WaveformView(waveform: Waveform.mockWaveform)
            .frame(width: 140, height: 50)
    }
}
