//
// Copyright 2022 New Vector Ltd
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

import DesignTokens
import SwiftUI

// MARK: SwiftUI

public extension Color {
    static let element = ElementColors()
}

public struct ElementColors {
    // MARK: - Legacy Compound
    
    private let colors = DesignTokens.CompoundColors()
    
    @available(swift, deprecated: 5.0, message: "Use textActionAccent/iconAccentTertiary from Compound.")
    public var brand: Color { colors.accent }
        
    // MARK: - Temp
    
    /// The background colour of a row in a Form or grouped List.
    ///
    /// This colour will be removed once Compound form styles are used everywhere.
    public var formRowBackground = Color.compound.bgCanvasDefaultLevel1
}
