//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import SwiftUI
import Testing

struct TimelineItemCellTests {
    /// A row taller or shorter than its content, as when the row's height hasn't caught up yet.
    @Test(arguments: [50.0, 200.0])
    func contentStaysAtTheVisualTopOfAStaleRow(rowHeight: CGFloat) throws {
        let host = try FlippedTableHost(rowHeight: rowHeight)
        
        let rowRect = host.visualRect(ofRow: 0)
        #expect(abs(rowRect.height - rowHeight) < 0.5)
        #expect(abs(host.visualContentRect(ofRow: 0).minY - rowRect.minY) < 0.5)
    }
    
    @Test(arguments: [44.0, 600.0])
    func rowsSizeToTheirContentWhateverTheEstimate(estimatedRowHeight: CGFloat) throws {
        let host = try FlippedTableHost(rowHeight: UITableView.automaticDimension, estimatedRowHeight: estimatedRowHeight)
        
        let rowRect = host.visualRect(ofRow: 0)
        #expect(abs(rowRect.height - FlippedTableHost.contentHeight) < 0.5)
        #expect(abs(host.visualContentRect(ofRow: 0).minY - rowRect.minY) < 0.5)
    }
    
    /// A header lost or gained without animation, by a live merge or split, or by a back-paginated page that the table
    /// applies at once or, while the user drags, later.
    @Test(arguments: [TimelineGroupStyle.single, .last], RegroupTableHost.OlderRowInsertion.allCases)
    func anUnanimatedRegroupResizesTheRowWithoutMovingTheBubble(from groupStyle: TimelineGroupStyle, olderRowInsertion: RegroupTableHost.OlderRowInsertion) async throws {
        let host = try RegroupTableHost(groupStyle: groupStyle)
        
        let motion = await host.motion(olderRowInsertion: olderRowInsertion) {
            host.regroup(to: groupStyle == .single ? .last : .single, animated: false)
        }
        
        #expect(motion.restingShift < 0.5, "Only the row's top changes, so the bubble's place shouldn't.")
        #expect(motion.largestDeviation < 0.5, "The bubble moved by \(motion.largestDeviation) pt while the row resized.")
        #expect(!motion.animatedTheTable)
        #expect(!motion.tweenedTheContent)
    }
    
    /// A live merge or split: the message above loses or gains its only reaction, which also moves the watched
    /// message's header, so both rows resize in the same layout pass.
    @Test(arguments: [true, false])
    func anUnanimatedRegroupResizesTheOtherChangedRowsWithoutAnimationToo(merging: Bool) async throws {
        let host = try RegroupTableHost(groupStyle: merging ? .single : .last,
                                        neighbourGroupStyle: merging ? .single : .first,
                                        neighbourHasReactions: merging)
        
        let motion = await host.motion {
            host.regroupWithTheNeighbour(to: merging ? .last : .single,
                                         neighbourTo: merging ? .first : .single,
                                         neighbourHasReactions: !merging)
        }
        
        #expect(motion.restingShift < 0.5, "Only the row's top changes, so the bubble's place shouldn't.")
        #expect(motion.largestDeviation < 0.5, "The bubble moved by \(motion.largestDeviation) pt while the rows resized.")
        #expect(!motion.animatedTheTable)
        #expect(!motion.tweenedTheContent)
    }
    
    /// Two updates in one turn, so the table shows them in one layout pass: an unanimated regroup, then at once one
    /// that toggles no header, as when back-pagination's spinner goes right after its page. The second update may
    /// resize the neighbour too.
    @Test(arguments: [false, true])
    func anUnanimatedRegroupStaysUnanimatedWhenAnotherUpdateLandsBeforeTheTableShowsIt(resizingTheNeighbour: Bool) async throws {
        let host = try RegroupTableHost(groupStyle: .single, neighbourHasReactions: true)
        
        let motion = await host.motion {
            host.regroup(to: .last, animated: false)
            host.updateWithoutRegrouping(removingTheNeighbourFooter: resizingTheNeighbour)
        }
        
        #expect(motion.restingShift < 0.5, "Only the row's top changes, so the bubble's place shouldn't.")
        #expect(motion.largestDeviation < 0.5, "The bubble moved by \(motion.largestDeviation) pt while the rows resized.")
        #expect(!motion.animatedTheTable)
        withKnownIssue("SwiftUI shows the later, animated update's change with its own transaction, which the table can't reach.") {
            #expect(!motion.tweenedTheContent)
        } when: {
            resizingTheNeighbour
        }
    }
    
    /// The neighbour's group style changes without a height change, so it never resizes for the unanimated update.
    @Test
    func aLaterResizeAnimatesOnceTheTableHasShownAnUnanimatedRegroup() async throws {
        let host = try RegroupTableHost(groupStyle: .single, neighbourHasReactions: true)
        
        let motion = await host.motion(after: {
            host.regroupWithTheNeighbour(to: .last, neighbourTo: .first, neighbourHasReactions: true)
        }, during: {
            host.resizeTheNeighbour()
        })
        
        #expect(motion.animatedTheTable)
        #expect(motion.tweenedTheContent)
    }
    
    /// The table runs the cell provider for the row again, as a reconfigure does, before it shows the regroup.
    @Test
    func aLaterResizeAnimatesOnceTheTableHasShownAnUnanimatedRegroupOfAReconfiguredRow() async throws {
        let host = try RegroupTableHost(groupStyle: .single, neighbourHasReactions: true)
        
        let motion = await host.motion(after: {
            host.regroup(to: .last, animated: false)
            host.reconfigureTheWatchedRow()
        }, during: {
            host.resizeTheNeighbour()
        })
        
        #expect(motion.animatedTheTable)
        #expect(motion.tweenedTheContent)
    }
    
    @Test
    func anAnimatedRegroupKeepsTheResizeAnimation() async throws {
        let host = try RegroupTableHost(groupStyle: .single)
        
        let motion = await host.motion {
            host.regroup(to: .last, animated: true)
        }
        
        #expect(motion.animatedTheTable)
        #expect(motion.tweenedTheContent)
        #expect(motion.largestDeviation > 10, "The sampling should see the resize animation move the bubble.")
    }
    
    /// A held send's previous bubble: its group style changes without a height change while its receipt goes.
    @Test
    func anUnanimatedRegroupWithoutAHeaderChangeKeepsTheResizeAnimation() async throws {
        let host = try RegroupTableHost(groupStyle: .single)
        
        let motion = await host.motion {
            host.regroup(to: .first, animated: false, removingTheFooter: true)
        }
        
        #expect(motion.animatedTheTable)
    }
    
    /// A new newest row lands while the previous newest one loses its delivery status, animated or, during a send
    /// hold, without animation. One motion means the previous row resizes in the insert's batch, not after it.
    @Test(arguments: [true, false], InsertTableHost.Trigger.allCases)
    func anInsertResizesThePreviousNewestRowInItsBatch(animated: Bool, trigger: InsertTableHost.Trigger) async throws {
        let host = try await InsertTableHost()
        
        let heights = await host.insertANewestRow(animated: animated, trigger: trigger, layingOutThePendingChange: true)
        
        #expect(abs(heights.rightAfterTheApply - InsertTableHost.rowHeight) < 0.5, "The receipt should go in the insert's batch.")
        #expect(abs(heights.settled - InsertTableHost.rowHeight) < 0.5)
    }
    
    /// Why the row is laid out before the insert: unless SwiftUI has already shown the change, the table keeps the
    /// row's old height through the batch and resizes it in a layout pass of its own. Nothing orders SwiftUI's update
    /// of the row before the table's, so only an insert made before SwiftUI updates anything shows it reliably.
    @Test(arguments: [true, false])
    func withoutALayoutThePreviousNewestRowResizesAfterTheInsertsBatch(animated: Bool) async throws {
        let host = try await InsertTableHost()
        
        let heights = await host.insertANewestRow(animated: animated, trigger: .directly, layingOutThePendingChange: false)
        
        #expect(abs(heights.rightAfterTheApply - InsertTableHost.rowHeightWithReceipt) < 0.5)
        #expect(abs(heights.settled - InsertTableHost.rowHeight) < 0.5)
    }
}

/// A flipped table, as in the timeline, whose cells show a probe view of a known height through `TimelineItemCell.setContent`.
private final class FlippedTableHost: NSObject, UITableViewDataSource {
    static let contentHeight: CGFloat = 100
    
    private let window: UIWindow
    private let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 390, height: 700), style: .plain)
    private var probes: [Int: UIView] = [:]
    
    init(rowHeight: CGFloat, estimatedRowHeight: CGFloat = 44) throws {
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        window = UIWindow(windowScene: scene)
        super.init()
        
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        tableView.register(TimelineItemCell.self, forCellReuseIdentifier: TimelineItemCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        tableView.rowHeight = rowHeight
        tableView.estimatedRowHeight = estimatedRowHeight
        tableView.dataSource = self
        window.addSubview(tableView)
        window.isHidden = false
        
        tableView.reloadData()
        tableView.layoutIfNeeded()
        // A second pass lets self-sizing rows settle on their measured heights.
        tableView.layoutIfNeeded()
    }
    
    func visualRect(ofRow row: Int) -> CGRect {
        tableView.convert(tableView.rectForRow(at: IndexPath(row: row, section: 0)), to: window)
    }
    
    func visualContentRect(ofRow row: Int) -> CGRect {
        guard let probe = probes[row] else {
            Issue.record("Row \(row) has no content")
            return .null
        }
        return probe.convert(probe.bounds, to: window)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TimelineItemCell.reuseIdentifier, for: indexPath)
        let probe = UIView()
        probes[indexPath.row] = probe
        (cell as? TimelineItemCell)?.setContent {
            Probe(view: probe)
                .frame(height: Self.contentHeight)
        }
        return cell
    }
}

private struct Probe: UIViewRepresentable {
    let view: UIView
    
    func makeUIView(context: Context) -> UIView {
        view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) { }
}

/// A flipped table whose middle row shows a bubble under a header that follows its view state's group style, as in
/// `TimelineItemBubbledStylerView`, through `TimelineItemCell.setContent`. The row above it, the older neighbour, does
/// the same over its reactions.
final class RegroupTableHost: NSObject {
    enum OlderRowInsertion: CaseIterable {
        case none
        case inTheSameFrame
        case aFewFramesLater
    }
    
    /// How far the bubble moved after a change, sampled every frame.
    struct Motion {
        /// Between the bubble's place before the change and after it.
        let restingShift: CGFloat
        /// The largest distance, on screen, between the bubble and its place before the change.
        let largestDeviation: CGFloat
        /// Whether any of the table's layers animated after the change.
        let animatedTheTable: Bool
        /// Whether SwiftUI animated a change to the watched row's or the neighbour's content after the change.
        let tweenedTheContent: Bool
    }
    
    private static let watchedRow = 1
    private static let neighbourRow = 2
    /// Longer than UIKit's resize animation.
    private static let sampledDuration: CFTimeInterval = 0.6
    
    private let window: UIWindow
    private let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 390, height: 700), style: .plain)
    private var dataSource: UITableViewDiffableDataSource<Int, Int>?
    private let viewState: RoomTimelineItemViewState
    private let footer = FooterState()
    private let bubble = UIView()
    private let neighbour: RoomTimelineItemViewState
    private let neighbourReactions: FooterState
    
    private var earlierChange: (() -> Void)?
    private var change: (() -> Void)?
    private var olderRowInsertion = OlderRowInsertion.none
    private var frame = 0
    private var changedAt: CFTimeInterval?
    private var topBeforeChange: CGFloat = 0
    private var largestDeviation: CGFloat = 0
    private var animatedTheTable = false
    private var tweenedTheContent = false
    private var samplingFinished: CheckedContinuation<Void, Never>?
    private var changeFrame: Int {
        earlierChange == nil ? 3 : 20
    }
    
    init(groupStyle: TimelineGroupStyle, neighbourGroupStyle: TimelineGroupStyle = .single, neighbourHasReactions: Bool = false) throws {
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        window = UIWindow(windowScene: scene)
        viewState = RoomTimelineItemViewState(type: .separator(.init(id: .virtual(uniqueID: .init("watched")), timestamp: .mock)), groupStyle: groupStyle)
        neighbour = RoomTimelineItemViewState(type: .separator(.init(id: .virtual(uniqueID: .init("neighbour")), timestamp: .mock)), groupStyle: neighbourGroupStyle)
        neighbourReactions = FooterState(isShown: neighbourHasReactions)
        super.init()
        
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        tableView.register(TimelineItemCell.self, forCellReuseIdentifier: TimelineItemCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, row in
            let cell = tableView.dequeueReusableCell(withIdentifier: TimelineItemCell.reuseIdentifier, for: indexPath)
            guard let self, let cell = cell as? TimelineItemCell else { return cell }
            if row == Self.watchedRow {
                cell.item = viewState
                cell.setContent { [viewState, footer, bubble] in
                    HeaderBubbleFooter(viewState: viewState, footer: footer, bubble: bubble) { [weak self] in self?.contentDidChange(animated: $0) }
                }
            } else if row == Self.neighbourRow {
                cell.item = neighbour
                cell.setContent { [neighbour, neighbourReactions] in
                    HeaderBubbleFooter(viewState: neighbour, footer: neighbourReactions, bubble: UIView()) { [weak self] in self?.contentDidChange(animated: $0) }
                }
            } else {
                cell.setContent {
                    Color.gray.frame(height: 60)
                }
            }
            return cell
        }
        window.addSubview(tableView)
        window.isHidden = false
        
        apply(rows: [0, 1, 2])
        tableView.layoutIfNeeded()
        // A second pass lets self-sizing rows settle on their measured heights.
        tableView.layoutIfNeeded()
    }
    
    func regroup(to groupStyle: TimelineGroupStyle, animated: Bool, removingTheFooter: Bool = false) {
        update(animated: animated, regrouping: [(viewState, groupStyle)]) {
            if removingTheFooter {
                footer.isShown = false
            }
        }
    }
    
    func regroupWithTheNeighbour(to groupStyle: TimelineGroupStyle, neighbourTo neighbourGroupStyle: TimelineGroupStyle, neighbourHasReactions: Bool) {
        update(animated: false, regrouping: [(viewState, groupStyle), (neighbour, neighbourGroupStyle)]) {
            neighbourReactions.isShown = neighbourHasReactions
        }
    }
    
    /// Stamps and reassigns every row, as the view model does, and regroups nothing.
    func updateWithoutRegrouping(removingTheNeighbourFooter: Bool) {
        let animatesResize = RegroupPolicy.animatesResizes(for: .other, togglesSenderDetails: false)
        for (viewState, groupStyle) in [(viewState, viewState.groupStyle), (neighbour, neighbour.groupStyle)] {
            viewState.animatesResize = animatesResize
            viewState.groupStyle = groupStyle
        }
        if removingTheNeighbourFooter {
            neighbourReactions.isShown = false
        }
    }
    
    func reconfigureTheWatchedRow() {
        guard var snapshot = dataSource?.snapshot() else { return }
        snapshot.reconfigureItems([Self.watchedRow])
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
    
    /// A resize that no timeline update causes, such as an image or a link preview loading.
    func resizeTheNeighbour() {
        neighbourReactions.isShown.toggle()
    }
    
    /// Makes the change in a display-link frame, as a timeline update lands between frames, then samples the bubble's
    /// on-screen top every frame until the row has settled. An earlier change lands some frames before, so the table
    /// has shown it by then.
    func motion(olderRowInsertion: OlderRowInsertion = .none, after earlierChange: (() -> Void)? = nil, during change: @escaping () -> Void) async -> Motion {
        self.earlierChange = earlierChange
        self.change = change
        self.olderRowInsertion = olderRowInsertion
        
        let displayLink = CADisplayLink(target: self, selector: #selector(sampleFrame))
        displayLink.add(to: .main, forMode: .common)
        await withCheckedContinuation { samplingFinished = $0 }
        displayLink.invalidate()
        
        let topAfterChange = bubble.convert(bubble.bounds, to: window).minY
        window.isHidden = true
        return Motion(restingShift: abs(topAfterChange - topBeforeChange),
                      largestDeviation: largestDeviation,
                      animatedTheTable: animatedTheTable,
                      tweenedTheContent: tweenedTheContent)
    }
    
    /// Changes the view states in one update, the way `TimelineViewModel.buildTimelineViews` does.
    private func update(animated: Bool, regrouping regroups: [(viewState: RoomTimelineItemViewState, groupStyle: TimelineGroupStyle)], alongside otherChanges: () -> Void) {
        let togglesSenderDetails = regroups.contains { $0.viewState.groupStyle.shouldShowSenderDetails != $0.groupStyle.shouldShowSenderDetails }
        let animatesResize = RegroupPolicy.animatesResizes(for: animated ? .newestInsert : .other, togglesSenderDetails: togglesSenderDetails)
        var transaction = Transaction()
        transaction.disablesAnimations = !animated
        withTransaction(transaction) {
            for (viewState, groupStyle) in regroups {
                viewState.animatesResize = animatesResize
                viewState.groupStyle = groupStyle
            }
            otherChanges()
        }
    }
    
    @objc private func sampleFrame(_ displayLink: CADisplayLink) {
        frame += 1
        
        guard let changedAt else {
            if frame == 3 {
                earlierChange?()
            }
            if frame == changeFrame {
                topBeforeChange = bubble.convert(bubble.bounds, to: window).minY
                change?()
                changedAt = displayLink.timestamp
                if olderRowInsertion == .inTheSameFrame {
                    insertAnOlderRow()
                }
            }
            return
        }
        
        if frame == changeFrame + 3, olderRowInsertion == .aFewFramesLater {
            insertAnOlderRow()
        }
        largestDeviation = max(largestDeviation, abs(presentedBubbleTop() - topBeforeChange))
        animatedTheTable = animatedTheTable || hasAnimations(tableView.layer)
        if displayLink.timestamp - changedAt > Self.sampledDuration || frame > 240 {
            samplingFinished?.resume()
            samplingFinished = nil
        }
    }
    
    private func contentDidChange(animated: Bool) {
        if changedAt != nil, animated {
            tweenedTheContent = true
        }
    }
    
    private func presentedBubbleTop() -> CGFloat {
        guard let layer = bubble.layer.presentation(), let windowLayer = window.layer.presentation() else {
            return bubble.convert(bubble.bounds, to: window).minY
        }
        return layer.convert(layer.bounds, to: windowLayer).minY
    }
    
    private func hasAnimations(_ layer: CALayer) -> Bool {
        !(layer.animationKeys() ?? []).isEmpty || (layer.sublayers ?? []).contains { hasAnimations($0) }
    }
    
    /// Unanimated, as for a back-paginated page.
    private func insertAnOlderRow() {
        apply(rows: [0, 1, 2, 3])
    }
    
    private func apply(rows: [Int]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(rows)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}

private final class FooterState: ObservableObject {
    @Published var isShown: Bool
    
    init(isShown: Bool = true) {
        self.isShown = isShown
    }
}

/// A 70 pt bubble under a 30 pt header shown for the first row of a group, over a 20 pt footer such as a receipt.
/// It animates its changes as `RoomTimelineItemView` does, and reports whether each change animated.
private struct HeaderBubbleFooter: View {
    @ObservedObject var viewState: RoomTimelineItemViewState
    @ObservedObject var footer: FooterState
    let bubble: UIView
    let didChange: (_ animated: Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if viewState.groupStyle.shouldShowSenderDetails {
                Color.red.frame(height: 30)
            }
            Probe(view: bubble)
                .frame(height: 70)
            if footer.isShown {
                Color.blue.frame(height: 20)
            }
        }
        .transaction { didChange($0.animation != nil) }
        .animation(.default, value: viewState.groupStyle)
        .animation(.default, value: footer.isShown)
    }
}

/// A flipped table inside a SwiftUI view, as in the timeline, whose rows show a 60 pt bubble and, for the newest row
/// only, a 20 pt receipt below it. The receipt follows the same published rows the table applies, as the delivery
/// status follows the timeline's view state.
final class InsertTableHost {
    /// How the insert reaches the table.
    enum Trigger: CaseIterable {
        /// In the turn the rows change, before SwiftUI has updated anything.
        case directly
        /// From the SwiftUI update the change causes, as `TimelineViewRepresentable` applies the timeline's items.
        case fromTheSwiftUIUpdate
    }
    
    /// The previous newest row's height right after the insert and once everything has settled.
    struct Heights {
        let rightAfterTheApply: CGFloat
        let settled: CGFloat
    }
    
    static let rowHeight: CGFloat = 60
    static let rowHeightWithReceipt: CGFloat = 80
    
    private let window: UIWindow
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let rows = PublishedRows(newestFirst: [1, 0])
    private var dataSource: UITableViewDiffableDataSource<Int, Int>?
    private var applyFromTheSwiftUIUpdate: (() -> Void)?
    private var heightRightAfterTheApply: CGFloat?
    
    init() async throws {
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        
        tableView.register(TimelineItemCell.self, forCellReuseIdentifier: TimelineItemCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [rows] tableView, indexPath, row in
            let cell = tableView.dequeueReusableCell(withIdentifier: TimelineItemCell.reuseIdentifier, for: indexPath)
            (cell as? TimelineItemCell)?.setContent {
                BubbleWithReceipt(row: row, rows: rows)
            }
            return cell
        }
        
        window.rootViewController = UIHostingController(rootView: TableRepresentable(tableView: tableView, rows: rows) { [weak self] in
            self?.applyFromTheSwiftUIUpdate?()
        })
        window.isHidden = false
        window.layoutIfNeeded()
        try #require(tableView.bounds.width > 0, "SwiftUI should have laid the table out.")
        
        apply(animated: false)
        tableView.layoutIfNeeded()
        // A second pass lets self-sizing rows settle on their measured heights.
        tableView.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(100))
        try #require(abs(heightOfRow(0) - Self.rowHeightWithReceipt) < 0.5, "The newest row should show its receipt.")
    }
    
    /// Inserts row 2 as the newest row, so row 1 loses its receipt, and measures row 1.
    func insertANewestRow(animated: Bool, trigger: Trigger, layingOutThePendingChange: Bool) async -> Heights {
        heightRightAfterTheApply = nil
        let insert = { [self] in
            apply(animated: animated, layingOutThePendingChangeOf: layingOutThePendingChange ? IndexPath(row: 0, section: 0) : nil)
        }
        
        switch trigger {
        case .directly:
            rows.newestFirst = [2, 1, 0]
            insert()
        case .fromTheSwiftUIUpdate:
            applyFromTheSwiftUIUpdate = insert
            rows.newestFirst = [2, 1, 0]
            let deadline = ContinuousClock.now + .seconds(1)
            while heightRightAfterTheApply == nil, ContinuousClock.now < deadline {
                try? await Task.sleep(for: .milliseconds(10))
            }
            applyFromTheSwiftUIUpdate = nil
        }
        
        // Longer than UIKit's row animation.
        try? await Task.sleep(for: .milliseconds(600))
        tableView.layoutIfNeeded()
        if heightRightAfterTheApply == nil {
            Issue.record("SwiftUI never updated the table for the new rows.")
        }
        let heights = Heights(rightAfterTheApply: heightRightAfterTheApply ?? 0, settled: heightOfRow(1))
        window.isHidden = true
        return heights
    }
    
    /// Applies the published rows as `TimelineTableViewController` does: animated as for any new newest row, or
    /// unanimated as for a held send's echo. Records the previous newest row's height right after the apply.
    private func apply(animated: Bool, layingOutThePendingChangeOf indexPath: IndexPath? = nil) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(rows.newestFirst)
        let layOutThePendingChange = { [tableView] in
            guard let indexPath else { return }
            (tableView.cellForRow(at: indexPath) as? TimelineItemCell)?.layOutPendingContentChange()
        }
        
        if animated {
            layOutThePendingChange()
            dataSource?.apply(snapshot, animatingDifferences: true)
            heightRightAfterTheApply = heightOfRow(1)
        } else {
            UIView.performWithoutAnimation {
                layOutThePendingChange()
                dataSource?.apply(snapshot, animatingDifferences: false)
                heightRightAfterTheApply = heightOfRow(1)
                tableView.layoutIfNeeded()
            }
        }
    }
    
    private func heightOfRow(_ row: Int) -> CGFloat {
        tableView.rectForRow(at: IndexPath(row: row, section: 0)).height
    }
}

private final class PublishedRows: ObservableObject {
    @Published var newestFirst: [Int]
    
    init(newestFirst: [Int]) {
        self.newestFirst = newestFirst
    }
}

private struct BubbleWithReceipt: View {
    let row: Int
    @ObservedObject var rows: PublishedRows
    
    var body: some View {
        VStack(spacing: 0) {
            Color.gray.frame(height: InsertTableHost.rowHeight)
            if rows.newestFirst.first == row {
                Color.blue.frame(height: InsertTableHost.rowHeightWithReceipt - InsertTableHost.rowHeight)
            }
        }
    }
}

/// Hosts the table the way `TimelineViewRepresentable` hosts the timeline, and reports each update of the rows.
private struct TableRepresentable: UIViewRepresentable {
    let tableView: UITableView
    @ObservedObject var rows: PublishedRows
    let rowsDidUpdate: () -> Void
    
    func makeUIView(context: Context) -> TableContainer {
        TableContainer(tableView: tableView)
    }
    
    func updateUIView(_ container: TableContainer, context: Context) {
        rowsDidUpdate()
    }
}

private final class TableContainer: UIView {
    private let tableView: UITableView
    
    init(tableView: UITableView) {
        self.tableView = tableView
        super.init(frame: .zero)
        addSubview(tableView)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available.")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        tableView.frame = bounds
    }
}
