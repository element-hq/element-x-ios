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

struct LocationMarkerView: View {
    var body: some View {
        Image(Asset.Images.locationMarker.name)
            .alignmentGuide(VerticalAlignment.center) { dimensions in
                dimensions[.bottom]
            }
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 5)
    }
}

struct LocationMarkerView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 30) {
            LocationMarkerView()

            LocationMarkerView()
                .colorScheme(.dark)
        }
    }
}
