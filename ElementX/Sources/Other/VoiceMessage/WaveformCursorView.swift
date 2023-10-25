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

struct WaveformCursorView: View {
    var color: Color = .compound.iconAccentTertiary

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(color)
    }
}

struct WaveformCursorView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        WaveformCursorView(color: .compound.iconAccentTertiary)
            .frame(width: 2, height: 25)
    }
}
