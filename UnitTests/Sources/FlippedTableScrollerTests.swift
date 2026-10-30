//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import SwiftUI
import Testing

final class FlippedTableScrollerTests {
    /// Has to outlive the table: without its window the table stops reporting window coordinates.
    private let window: UIWindow
    private let rows = Rows()
    private let scrollCounter = ScrollCounter()
    
    init() throws {
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
    }
    
    isolated deinit {
        // The scene keeps the window, which would lay the table out again once `rows`, its weak data source, is gone.
        window.rootViewController = nil
        window.subviews.forEach { $0.removeFromSuperview() }
        window.isHidden = true
    }
    
    @Test(arguments: ClampTrigger.allCases)
    func anOutOfRangeOffsetIsClamped(by trigger: ClampTrigger) {
        // Documents the UIKit fact the scroller exists for.
        let (table, _) = makeTable()
        table.contentOffset.y = -120
        fire(trigger, on: table)
        #expect(table.contentOffset.y > -120)
    }
    
    @Test(arguments: ClampTrigger.allCases)
    func widenedInsetsKeepAnOutOfRangeOffset(through trigger: ClampTrigger) {
        let (table, scroller) = makeTable()
        let added = scroller.widenInsets(toAllow: -120)
        table.contentOffset.y = -120
        fire(trigger, on: table)
        #expect(table.contentOffset.y == -120)
        #expect(added.top == 120)
    }
    
    /// The 4 rows take 200 pt of the 400 pt table, so the range ends where it starts: the bottom inset has to make up the
    /// rest of the table as well as the move, as when a held echo lands in a short timeline. A taller frame would move
    /// this end of the range itself, so it isn't a trigger here.
    @Test(arguments: [ClampTrigger.insetWrite, .contentSizeChange])
    func widenedInsetsKeepAnOffsetPastTheRowsOfAShortTable(through trigger: ClampTrigger) {
        rows.count = 4
        let (table, scroller) = makeTable()
        let added = scroller.widenInsets(toAllow: 50)
        table.bounds.origin.y = 50
        fire(trigger, on: table)
        #expect(table.contentOffset.y == 50)
        #expect(added == Edge.oldest.insets(250))
    }
    
    @Test
    func anInRangeOffsetNeedsNoWidening() {
        let (table, scroller) = makeTable()
        let original = table.contentInset
        #expect(scroller.widenInsets(toAllow: 30) == .zero)
        #expect(scroller.moveRowsVisually(by: 30) == .zero)
        #expect(table.contentInset == original)
    }
    
    @Test
    func wideningOnlyAddsWhatTheExistingInsetsDontAlreadyAllow() {
        let (table, scroller) = makeTable()
        table.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 10, right: 0)
        // The offsets in range are now -20 to 1110.
        #expect(scroller.widenInsets(toAllow: -120) == UIEdgeInsets(top: 100, left: 0, bottom: 0, right: 0))
        #expect(scroller.widenInsets(toAllow: 1150) == UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0))
    }
    
    @Test
    func aRowsVisualTopIsItsTopEdgeOnScreen() {
        let (_, scroller) = makeTable()
        // The table is flipped, so the first row sits at the bottom of the 400 pt table, 50 pt tall.
        #expect(abs(scroller.visualTop(of: IndexPath(row: 0, section: 0)) - 350) < 0.5)
    }
    
    @Test
    func movingRowsVisuallyMovesARowsWindowTopByThatMuch() {
        let (_, scroller) = makeTable()
        let indexPath = IndexPath(row: 2, section: 0)
        let before = scroller.visualTop(of: indexPath)
        scroller.moveRowsVisually(by: 30)
        #expect(abs(scroller.visualTop(of: indexPath) - (before + 30)) < 0.5)
    }
    
    @Test(arguments: Edge.allCases)
    func movingRowsVisuallyBeyondAnEdgeWidensTheInsetsAndStillMovesTheRows(_ edge: Edge) {
        let (table, scroller) = makeTable()
        table.contentOffset.y = offset(0, beyond: edge, in: table)
        let indexPath = IndexPath(row: 2, section: 0)
        let before = scroller.visualTop(of: indexPath)
        
        let added = scroller.moveRowsVisually(by: edge.outwardSign * 40)
        let moved = scroller.visualTop(of: indexPath)
        fire(.insetWrite, on: table)
        
        #expect(added == edge.insets(40))
        #expect(abs(moved - (before + edge.outwardSign * 40)) < 0.5)
        #expect(abs(scroller.visualTop(of: indexPath) - moved) < 0.5, "The widened insets should keep the rows where they were moved.")
    }
    
    @Test
    func aMoveOfLessThanHalfAPointIsIgnored() {
        let (table, scroller) = makeTable()
        let original = table.contentOffset.y
        #expect(scroller.moveRowsVisually(by: 0.4) == .zero)
        #expect(table.contentOffset.y == original)
    }
    
    @Test(arguments: Edge.allCases)
    func removingInsetsRestoresTheOriginalInsets(_ edge: Edge) {
        let (table, scroller) = makeTable()
        let original = table.contentInset
        let added = scroller.widenInsets(toAllow: offset(80, beyond: edge, in: table))
        #expect(added == edge.insets(80))
        scroller.removeInsets(added)
        #expect(table.contentInset == original)
    }
    
    @Test(arguments: Edge.allCases)
    func removingInsetsKeepsAnOffsetInsideTheRestoredRange(_ edge: Edge) {
        let (table, scroller) = makeTable()
        let original = table.contentInset
        table.contentOffset.y = offset(0, beyond: edge, in: table)
        let added = scroller.moveRowsVisually(by: edge.outwardSign * 60)
        #expect(scroller.moveRowsVisually(by: edge.outwardSign * -90) == .zero, "Back inside the widened range, nothing more is needed.")
        let indexPath = IndexPath(row: 2, section: 0)
        let before = scroller.visualTop(of: indexPath)
        
        scroller.removeInsets(added)
        
        #expect(table.contentInset == original)
        #expect(abs(scroller.visualTop(of: indexPath) - before) < 0.5, "The pinned rows shouldn't move when the insets go.")
    }
    
    @Test(arguments: Edge.allCases)
    func removingInsetsSnapsAnOffsetOutsideTheRestoredRangeBackToItsEnd(_ edge: Edge) {
        // Documents the trap `removeInsets` warns about: the callers have to move the offset back first.
        let (table, scroller) = makeTable()
        table.contentOffset.y = offset(0, beyond: edge, in: table)
        let added = scroller.moveRowsVisually(by: edge.outwardSign * 60)
        #expect(table.contentOffset.y == offset(60, beyond: edge, in: table))
        
        scroller.removeInsets(added)
        
        #expect(table.contentOffset.y == offset(0, beyond: edge, in: table))
    }
    
    @Test(arguments: Edge.allCases)
    func insetsTheOffsetStillNeedsStay(_ edge: Edge) {
        let (table, scroller) = makeTable()
        table.contentOffset.y = offset(0, beyond: edge, in: table)
        let added = scroller.moveRowsVisually(by: edge.outwardSign * 60)
        let insets = table.contentInset
        
        #expect(scroller.removeInsetsNoLongerNeeded(from: added) == added)
        
        #expect(table.contentInset == insets)
        #expect(table.contentOffset.y == offset(60, beyond: edge, in: table))
    }
    
    @Test(arguments: Edge.allCases)
    func insetsGoOnceTheOffsetHasLeftTheirSpace(_ edge: Edge) {
        let (table, scroller) = makeTable()
        let original = table.contentInset
        table.contentOffset.y = offset(0, beyond: edge, in: table)
        let added = scroller.moveRowsVisually(by: edge.outwardSign * 60)
        scroller.moveRowsVisually(by: edge.outwardSign * -90)
        let indexPath = IndexPath(row: 2, section: 0)
        let before = scroller.visualTop(of: indexPath)
        
        #expect(scroller.removeInsetsNoLongerNeeded(from: added) == .zero)
        
        #expect(table.contentInset == original)
        #expect(abs(scroller.visualTop(of: indexPath) - before) < 0.5, "The rows shouldn't move when the insets go.")
    }
    
    @Test
    func onlyTheEndTheOffsetHasLeftGoes() throws {
        let (table, scroller) = makeTable()
        var added = scroller.moveRowsVisually(by: -60)
        added += scroller.widenInsets(toAllow: offset(40, beyond: .oldest, in: table))
        try #require(added == UIEdgeInsets(top: 60, left: 0, bottom: 40, right: 0))
        
        #expect(scroller.removeInsetsNoLongerNeeded(from: added) == Edge.newest.insets(60))
        
        #expect(table.contentInset == Edge.newest.insets(60))
        #expect(table.contentOffset.y == -60)
    }
    
    @Test
    func noInsetsGoWhileTheOffsetIsPastAnEnd() {
        // Like a bounce at the oldest end while the newest end still has the space a restore made.
        let (table, scroller) = makeTable()
        let added = scroller.widenInsets(toAllow: -60)
        table.bounds.origin.y = offset(30, beyond: .oldest, in: table)
        
        #expect(scroller.removeInsetsNoLongerNeeded(from: added) == added)
        
        #expect(table.contentInset == added)
        #expect(table.contentOffset.y == offset(30, beyond: .oldest, in: table))
    }
    
    @Test
    func aBottomInsetThatStretchesAShortTableStays() {
        // The 4 rows take 200 pt of the 400 pt table, so the range ends where it starts unless the bottom inset stretches it.
        rows.count = 4
        let (table, scroller) = makeTable()
        var added = scroller.moveRowsVisually(by: -60)
        table.contentInset.bottom += 190
        added.bottom += 190
        table.bounds.origin.y = -30
        
        #expect(scroller.removeInsetsNoLongerNeeded(from: added) == added)
        
        #expect(table.contentOffset.y == -30)
    }
    
    @Test
    func addingInsetsSumsEachEdge() {
        var insets = UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)
        insets += UIEdgeInsets(top: 10, left: 20, bottom: 30, right: 40)
        #expect(insets == UIEdgeInsets(top: 11, left: 22, bottom: 33, right: 44))
    }
    
    @Test(arguments: AnimatedWrite.allCases)
    func geometryWritesDontPickUpTheAnimationTheyAreCalledInside(_ write: AnimatedWrite) {
        let (table, scroller) = makeTable()
        let writeUnderTest: () -> Void
        switch write {
        case .moveRowsPastAnEdge:
            writeUnderTest = { _ = scroller.moveRowsVisually(by: -60) }
        case .widenInsets:
            // An inset write only animates when it clamps: the offset is left out of range at one end, and the widening is at the other.
            table.bounds.origin.y = -60
            let farEnd = offset(40, beyond: .oldest, in: table)
            writeUnderTest = { _ = scroller.widenInsets(toAllow: farEnd) }
        case .removeInsets:
            // The restore clamps: the offset is outside the range the table has without the insets.
            let added = scroller.moveRowsVisually(by: -60)
            writeUnderTest = { scroller.removeInsets(added) }
        }
        #expect(animationKeys(of: table).isEmpty)
        
        UIView.animate(withDuration: 1, animations: writeUnderTest)
        
        #expect(animationKeys(of: table).isEmpty, "The table picked up the animations \(animationKeys(of: table)).")
    }
    
    @Test(arguments: Edge.allCases)
    func theOffsetRangeIncludesTheInsetsTheSystemAdds(_ edge: Edge) throws {
        // The timeline keeps the default adjustment, so a safe area lands in `adjustedContentInset` and not in `contentInset`.
        let (table, scroller) = makeTableUnderSafeArea()
        let systemInset = switch edge {
        case .newest: table.adjustedContentInset.top - table.contentInset.top
        case .oldest: table.adjustedContentInset.bottom - table.contentInset.bottom
        }
        try #require(systemInset > 0, "The test needs a safe area, or it can't tell the adjusted insets from the plain ones.")
        let end = switch edge {
        case .newest: -systemInset
        case .oldest: table.contentSize.height + systemInset - table.bounds.height
        }
        
        #expect(scroller.widenInsets(toAllow: end) == .zero, "The system's own inset already allows this end.")
        let beyond = end + edge.outwardSign * 120
        #expect(scroller.widenInsets(toAllow: beyond) == edge.insets(120))
        table.contentOffset.y = beyond
        fire(.insetWrite, on: table)
        #expect(table.contentOffset.y == beyond)
    }
    
    @Test
    func movingRowsVisuallyDoesNotCallTheScrollDelegate() {
        let (table, scroller) = makeTable()
        table.delegate = scrollCounter
        
        table.contentOffset.y += 1
        #expect(scrollCounter.callCount == 1, "The control: a contentOffset write notifies the delegate.")
        
        scroller.moveRowsVisually(by: 30)
        #expect(scrollCounter.callCount == 1, "A bounds write doesn't, so callers have to refresh what they derive from scrolling.")
    }
    
    @Test(arguments: Edge.allCases)
    func movingRowsVisuallyBeyondAnEdgeDoesNotCallTheScrollDelegate(_ edge: Edge) {
        let (table, scroller) = makeTable()
        table.contentOffset.y = offset(0, beyond: edge, in: table)
        table.delegate = scrollCounter
        
        #expect(scroller.moveRowsVisually(by: edge.outwardSign * 40) == edge.insets(40))
        
        #expect(scrollCounter.callCount == 0)
    }
    
    // MARK: - Helpers
    
    private func makeTable() -> (UITableView, FlippedTableScroller) {
        let table = makeFlippedTable(height: 400)
        // Keeps the device's safe area out of the offsets, so the numbers are the same everywhere.
        table.contentInsetAdjustmentBehavior = .never
        window.addSubview(table)
        return layOut(table)
    }
    
    /// Like the timeline: it keeps the default adjustment, and the table spans the window, so its ends are under a safe area.
    private func makeTableUnderSafeArea() -> (UITableView, FlippedTableScroller) {
        let host = UIViewController()
        host.additionalSafeAreaInsets = UIEdgeInsets(top: 30, left: 0, bottom: 20, right: 0)
        window.rootViewController = host
        window.isHidden = false
        window.layoutIfNeeded()
        let table = makeFlippedTable(height: host.view.bounds.height)
        host.view.addSubview(table)
        return layOut(table)
    }
    
    private func makeFlippedTable(height: CGFloat) -> UITableView {
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: 390, height: height), style: .plain)
        table.transform = CGAffineTransform(scaleX: 1, y: -1)
        table.rowHeight = 50
        table.dataSource = rows
        return table
    }
    
    private func layOut(_ table: UITableView) -> (UITableView, FlippedTableScroller) {
        window.isHidden = false
        window.layoutIfNeeded()
        table.reloadData()
        table.layoutIfNeeded()
        return (table, FlippedTableScroller(tableView: table))
    }
    
    private func animationKeys(of table: UITableView) -> [String] {
        table.layer.animationKeys() ?? []
    }
    
    private func fire(_ trigger: ClampTrigger, on table: UITableView) {
        switch trigger {
        case .insetWrite:
            // UIKit ignores a write of the value the insets already have, so this one changes them.
            table.contentInset.bottom += 1
        case .frameChange:
            table.frame.size.height += 1
        case .contentSizeChange:
            // A new row at the oldest end, like the echo of a send or a new page.
            rows.count += 1
            table.insertRows(at: [IndexPath(row: rows.count - 1, section: 0)], with: .none)
        }
        table.layoutIfNeeded()
    }
    
    /// The offset `distance` points past the end of the offset range at `edge`.
    private func offset(_ distance: CGFloat, beyond edge: Edge, in table: UITableView) -> CGFloat {
        switch edge {
        case .newest: -distance
        case .oldest: table.contentSize.height - table.bounds.height + distance
        }
    }
    
    /// What makes UIKit clamp an offset that is out of range.
    nonisolated enum ClampTrigger: CaseIterable {
        case insetWrite
        case frameChange
        case contentSizeChange
    }
    
    /// A scroller call that has to stay unanimated when something else animates around it.
    nonisolated enum AnimatedWrite: CaseIterable {
        case moveRowsPastAnEdge
        case widenInsets
        case removeInsets
    }
    
    /// An end of the table's offset range. The table is flipped, so the newest row's end is offset 0.
    nonisolated enum Edge: CaseIterable {
        case newest
        case oldest
        
        /// The sign of the move that takes the rows past this end.
        var outwardSign: CGFloat {
            switch self {
            case .newest: -1
            case .oldest: 1
            }
        }
        
        func insets(_ amount: CGFloat) -> UIEdgeInsets {
            switch self {
            case .newest: UIEdgeInsets(top: amount, left: 0, bottom: 0, right: 0)
            case .oldest: UIEdgeInsets(top: 0, left: 0, bottom: amount, right: 0)
            }
        }
    }
    
    private final class Rows: NSObject, UITableViewDataSource {
        var count = 30
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            UITableViewCell()
        }
    }
    
    private final class ScrollCounter: NSObject, UITableViewDelegate {
        private(set) var callCount = 0
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            callCount += 1
        }
    }
}
