//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import WysiwygComposer

// periphery: ignore - markdown protocol
protocol ComposerToolbarViewModelProtocol {
    var actions: AnyPublisher<ComposerToolbarViewModelAction, Never> { get }
    var context: ComposerToolbarViewModelType.Context { get }
    var keyCommands: [WysiwygKeyCommand] { get }

    func process(timelineAction: TimelineComposerAction)
    func loadDraft() async
    func saveDraft()
}
