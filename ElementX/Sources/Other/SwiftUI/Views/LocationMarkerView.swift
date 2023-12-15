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
import SwiftUI

struct LocationMarkerView: View {
    var mode: Mode = .map
    enum Mode { case map, button }
    
    private let pinColor: Color = .compound.iconOnSolidPrimary
    private let pinInsets = EdgeInsets(top: 13, leading: 12, bottom: 15, trailing: 12)
    private let buttonScale: Double = 28 / 52
    
    var body: some View {
        switch mode {
        case .map: mapMarker
        case .button: buttonMarker
        }
    }
    
    var mapMarker: some View {
        CompoundIcon(asset: Asset.Images.locationPinSolid)
            .dynamicTypeSize(.large)
            .foregroundStyle(pinColor)
            .padding(pinInsets)
            .background {
                backgroundShape
                    .shadow(color: .black.opacity(0.2), radius: 4.1129, x: 0, y: 4.93548)
            }
            .alignmentGuide(VerticalAlignment.center) { dimensions in
                dimensions[.bottom]
            }
    }
    
    var buttonMarker: some View {
        CompoundIcon(asset: Asset.Images.locationPinSolid, size: .custom(13), relativeTo: .body)
            .foregroundStyle(pinColor)
            .scaledPadding(.top, pinInsets.top * buttonScale)
            .scaledPadding(.bottom, pinInsets.bottom * buttonScale)
            .scaledPadding(.horizontal, pinInsets.leading * buttonScale)
            .background {
                backgroundShape
            }
    }
    
    var backgroundShape: some View {
        Image(asset: Asset.Images.locationMarkerShape)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .foregroundStyle(.compound.iconPrimary)
    }
}

struct LocationMarkerView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 30) {
            LocationMarkerView()

            LocationMarkerView()
                .colorScheme(.dark)
            
            LocationMarkerView(mode: .button)

            LocationMarkerView(mode: .button)
                .colorScheme(.dark)
        }
    }
}
