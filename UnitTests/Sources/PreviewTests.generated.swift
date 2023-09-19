// Generated using Sourcery 2.0.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all
// swiftformat:disable all

import XCTest
import SwiftUI
import Prefire

@testable import SnapshotTesting
#if canImport(AccessibilitySnapshot)
    import AccessibilitySnapshot
#endif
@testable import ElementX

class PreviewTests: XCTestCase {
    private let deviceConfig: ViewImageConfig = .iPhoneX
    private let simulatorDevice = "iPhone14"

    override func setUp() {
        super.setUp()

        checkEnvironments()
        UIView.setAnimationsEnabled(false)
    }

    func test_timelineItemStyler() {
        for preview in TimelineItemStyler_Previews._allPreviews {
            assertSnapshots(matching: preview)
        }
    }

    // MARK: Private

    private func assertSnapshots(matching preview: _Preview, testName: String = #function) {
        let isScreen = preview.layout == .device
        let device = preview.device?.snapshotDevice() ?? deviceConfig
        var delay: TimeInterval = 0
        var precision: Float = 0.99

        let view = preview.content
            .onPreferenceChange(DelayPreferenceKey.self) { delay = $0 }
            .onPreferenceChange(PrecisionPreferenceKey.self) { precision = $0 }

        let matchingView = isScreen ? AnyView(view) : AnyView(view
            .frame(width: device.size?.width)
            .fixedSize(horizontal: false, vertical: true)
        )

        assertSnapshot(
            matching: matchingView,
            as: .prefireImage(precision: { precision }, duration: { delay }, layout: isScreen ? .device(config: device) : .sizeThatFits),
            named: preview.displayName,
            testName: testName
        )

        #if canImport(AccessibilitySnapshot)
            let vc = UIHostingController(rootView: matchingView)
            vc.view.frame = UIScreen.main.bounds
            assertSnapshot(
                matching: vc,
                as: .wait(for: delay, on: .accessibilityImage(showActivationPoints: .always)),
                named: preview.displayName.map { $0 + ".accessibility" },
                testName: testName
            )
        #endif
    }

    /// Check environments to avoid problems with snapshots on different devices or OS.
    private func checkEnvironments() {
        let deviceModel = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"]
        guard deviceModel?.contains(simulatorDevice) ?? false else {
            fatalError("Switch to using \(simulatorDevice) for these tests.")
        }
    }
}

// MARK: - SnapshotTesting + Extensions

private extension PreviewDevice {
    func snapshotDevice() -> ViewImageConfig? {
        switch rawValue {
        case "iPhone 14", "iPhone 13", "iPhone 12", "iPhone 11", "iPhone 10":
            return .iPhoneX
        case "iPhone 6", "iPhone 6s", "iPhone 7", "iPhone 8":
            return .iPhone8
        case "iPhone 6 Plus", "iPhone 6s Plus", "iPhone 8 Plus":
            return .iPhone8Plus
        case "iPhone SE (1st generation)", "iPhone SE (2nd generation)":
            return .iPhoneSe
        default: return nil
        }
    }
}

private extension Snapshotting where Value: SwiftUI.View, Format == UIImage {
    static func prefireImage(
        drawHierarchyInKeyWindow: Bool = false,
        precision: @escaping () -> Float,
        duration: @escaping () -> TimeInterval,
        layout: SwiftUISnapshotLayout = .sizeThatFits,
        traits: UITraitCollection = .init()
    ) -> Snapshotting {
        let config: ViewImageConfig

        switch layout {
        #if os(iOS) || os(tvOS)
        case let .device(config: deviceConfig):
            config = deviceConfig
        #endif
        case .sizeThatFits:
            config = .init(safeArea: .zero, size: nil, traits: traits)
        case let .fixed(width: width, height: height):
            let size = CGSize(width: width, height: height)
            config = .init(safeArea: .zero, size: size, traits: traits)
        }

        return SimplySnapshotting<UIImage>(pathExtension: "png", diffing: .prefireImage(precision: precision, scale: traits.displayScale))
            .asyncPullback { view in
                var config = config

                let controller: UIViewController

                if config.size != nil {
                    controller = UIHostingController(rootView: view)
                } else {
                    let hostingController = UIHostingController(rootView: view)

                    let maxSize = CGSize.zero
                    config.size = hostingController.sizeThatFits(in: maxSize)

                    controller = hostingController
                }

                return Async<UIImage> { callback in
                    let strategy = snapshotView(
                        config: config,
                        drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
                        traits: traits,
                        view: controller.view,
                        viewController: controller
                    )

                    let duration = duration()
                    if duration != .zero {
                        let expectation = XCTestExpectation(description: "Wait")
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            expectation.fulfill()
                        }
                        _ = XCTWaiter.wait(for: [expectation], timeout: duration + 1)
                    }
                    strategy.run(callback)
                }
            }
    }
}

private extension Diffing where Value == UIImage {
    static func prefireImage(precision: @escaping () -> Float, scale: CGFloat?) -> Diffing {
        lazy var originalDiffing = Diffing.image(precision: precision(), scale: scale)
        return Diffing(
            toData: { originalDiffing.toData($0) },
            fromData: { originalDiffing.fromData($0) },
            diff: { originalDiffing.diff($0, $1) }
        )
    }
}
