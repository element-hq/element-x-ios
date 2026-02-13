// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all
// swiftformat:disable all

import Testing
@testable import Compound

extension PreviewTests {

    // MARK: - PreviewProvider

    @Test("BigIcon")
    func bigIcon() async throws {
        for (index, preview) in BigIcon_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test("CompoundButtonStyle")
    func compoundButtonStyle() async throws {
        for (index, preview) in CompoundButtonStyle_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test("CompoundIcon")
    func compoundIcon() async throws {
        for (index, preview) in CompoundIcon_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test("CompoundToggleStyle")
    func compoundToggleStyle() async throws {
        for (index, preview) in CompoundToggleStyle_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test("ListInlinePicker")
    func listInlinePicker() async throws {
        for (index, preview) in ListInlinePicker_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test("ListRowAccessory")
    func listRowAccessory() async throws {
        for (index, preview) in ListRowAccessory_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test("ListRowButtonStyle")
    func listRowButtonStyle() async throws {
        for (index, preview) in ListRowButtonStyle_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test("ListRowLabel")
    func listRowLabel() async throws {
        for (index, preview) in ListRowLabel_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test("ListRowLoadingSelection")
    func listRowLoadingSelection() async throws {
        for (index, preview) in ListRowLoadingSelection_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test("ListRowTrailingSection")
    func listRowTrailingSection() async throws {
        for (index, preview) in ListRowTrailingSection_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test("ListRow")
    func listRow() async throws {
        for (index, preview) in ListRow_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test("ListTextStyles")
    func listTextStyles() async throws {
        for (index, preview) in ListTextStyles_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test("ScaledFrameModifier")
    func scaledFrameModifier() async throws {
        for (index, preview) in ScaledFrameModifier_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test("ScaledOffsetModifier")
    func scaledOffsetModifier() async throws {
        for (index, preview) in ScaledOffsetModifier_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test("ScaledPaddingModifier")
    func scaledPaddingModifier() async throws {
        for (index, preview) in ScaledPaddingModifier_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test("SearchStyle")
    func searchStyle() async throws {
        for (index, preview) in SearchStyle_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test("SendButton")
    func sendButton() async throws {
        for (index, preview) in SendButton_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    @Test("TitleAndIcon")
    func titleAndIcon() async throws {
        for (index, preview) in TitleAndIcon_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }
}

// swiftlint:enable all
// swiftformat:enable all
