// 
// Copyright 2025 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import CompoundDesignTokens
import SwiftUI

public extension Gradient {
    /// The gradients used by Element as defined in Compound Design Tokens.
    static let compound = CompoundGradients()
}

/// The gradients used by Element as defined in Compound Design Tokens.
/// This struct only contains the gradients assembled from the individual colour stops.
public struct CompoundGradients {
    // We need to use computed properties here so that the gradients include the
    // latest token overrides that have been applied since the struct was created.
    public var action: Gradient { .init(colors: [.compound.gradientActionStop1,
                                                 .compound.gradientActionStop2,
                                                 .compound.gradientActionStop3,
                                                 .compound.gradientActionStop4]) }
    public var subtle: Gradient { .init(colors: [.compound.gradientSubtleStop1,
                                                 .compound.gradientSubtleStop2,
                                                 .compound.gradientSubtleStop3,
                                                 .compound.gradientSubtleStop4,
                                                 .compound.gradientSubtleStop5,
                                                 .compound.gradientSubtleStop6]) }
    public var info: Gradient { .init(colors: [.compound.gradientInfoStop1,
                                               .compound.gradientInfoStop2,
                                               .compound.gradientInfoStop3,
                                               .compound.gradientInfoStop4,
                                               .compound.gradientInfoStop5,
                                               .compound.gradientInfoStop6]) }
}
