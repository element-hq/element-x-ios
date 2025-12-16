// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all
// swiftformat:disable all

import XCTest
@testable import Compound

extension PreviewTests {

    // MARK: - PreviewProvider

    func testBigIcon() async throws {
        for (index, preview) in BigIcon_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testCompoundButtonStyle() async throws {
        for (index, preview) in CompoundButtonStyle_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testCompoundIcon() async throws {
        for (index, preview) in CompoundIcon_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testCompoundToggleStyle() async throws {
        for (index, preview) in CompoundToggleStyle_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testListInlinePicker() async throws {
        for (index, preview) in ListInlinePicker_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testListRowAccessory() async throws {
        for (index, preview) in ListRowAccessory_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testListRowButtonStyle() async throws {
        for (index, preview) in ListRowButtonStyle_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testListRowLabel() async throws {
        for (index, preview) in ListRowLabel_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testListRowLoadingSelection() async throws {
        for (index, preview) in ListRowLoadingSelection_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testListRowTrailingSection() async throws {
        for (index, preview) in ListRowTrailingSection_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testListRow() async throws {
        for (index, preview) in ListRow_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testListTextStyles() async throws {
        for (index, preview) in ListTextStyles_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testScaledFrameModifier() async throws {
        for (index, preview) in ScaledFrameModifier_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testScaledOffsetModifier() async throws {
        for (index, preview) in ScaledOffsetModifier_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testScaledPaddingModifier() async throws {
        for (index, preview) in ScaledPaddingModifier_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSearchStyle() async throws {
        for (index, preview) in SearchStyle_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testSendButton() async throws {
        for (index, preview) in SendButton_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }

    func testTitleAndIcon() async throws {
        for (index, preview) in TitleAndIcon_Previews._allPreviews.enumerated() {
            try await assertSnapshots(matching: preview, step: index)
        }
    }
}

// swiftlint:enable all
// swiftformat:enable all
