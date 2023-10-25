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

import Compound
import Foundation
import SwiftUI

struct VoiceMessageRecordingButtonTooltipView: View {
    var text: String
    var radius: CGFloat = 4
    var corners: UIRectCorner = .allCorners
    @ScaledMetric var pointerHeight: CGFloat = 6
    @ScaledMetric var pointerWidth: CGFloat = 10
    var pointerLocation: CGFloat = 10
    var pointerLocationCoordinateSpace: CoordinateSpace = .local

    var body: some View {
        Text(text)
            .font(.compound.bodySMSemibold)
            .foregroundColor(.compound.textOnSolidPrimary)
            .padding(6)
            .background(
                GeometryReader { geometry in
                    TooltipShape(radius: radius,
                                 corners: corners,
                                 pointerHeight: pointerHeight,
                                 pointerWidth: pointerWidth,
                                 pointerLocation: localPointerLocation(using: geometry))
                        .fill(.compound.bgActionPrimaryRest)
                }
            )
    }
    
    private func localPointerLocation(using geometry: GeometryProxy) -> CGFloat {
        let frame = geometry.frame(in: pointerLocationCoordinateSpace)
        let minX = radius + pointerWidth / 2
        let maxX = geometry.size.width - radius - pointerWidth / 2
        return min(max(minX, pointerLocation - frame.minX), maxX)
    }
}

private struct TooltipShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    var pointerHeight: CGFloat
    var pointerWidth: CGFloat
    var pointerLocation: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.size.width
        let height = rect.size.height

        var topLeft: CGFloat = corners.contains(.topLeft) ? radius : 0.0
        var topRight: CGFloat = corners.contains(.topRight) ? radius : 0.0
        var bottomLeft: CGFloat = corners.contains(.bottomLeft) ? radius : 0.0
        var bottomRight: CGFloat = corners.contains(.bottomRight) ? radius : 0.0
        
        // Make sure we do not exceed the size of the rectangle
        topRight = min(min(topRight, height / 2), width / 2)
        topLeft = min(min(topLeft, height / 2), width / 2)
        bottomLeft = min(min(bottomLeft, height / 2), width / 2)
        bottomRight = min(min(bottomRight, height / 2), width / 2)

        path.move(to: CGPoint(x: width / 2.0, y: 0))
        path.addLine(to: CGPoint(x: width - topRight, y: 0))
        path.addArc(center: CGPoint(x: width - topRight, y: topRight), radius: topRight,
                    startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)

        path.addLine(to: CGPoint(x: width, y: height - bottomRight))
        path.addArc(center: CGPoint(x: width - bottomRight, y: height - bottomRight), radius: bottomRight,
                    startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)

        path.addLine(to: CGPoint(x: pointerLocation + (pointerWidth / 2.0), y: height))
        path.addLine(to: CGPoint(x: pointerLocation, y: height + pointerHeight))
        path.addLine(to: CGPoint(x: pointerLocation - (pointerWidth / 2.0), y: height))
        
        path.addLine(to: CGPoint(x: bottomLeft, y: height))
        path.addArc(center: CGPoint(x: bottomLeft, y: height - bottomLeft), radius: bottomLeft,
                    startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)

        path.addLine(to: CGPoint(x: 0, y: topLeft))
        path.addArc(center: CGPoint(x: topLeft, y: topLeft), radius: topLeft,
                    startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
        path.closeSubpath()

        return path
    }
}

struct VoiceMessageRecordingButtonTooltipView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VoiceMessageRecordingButtonTooltipView(text: "Hold to record")
            .fixedSize()
    }
}
