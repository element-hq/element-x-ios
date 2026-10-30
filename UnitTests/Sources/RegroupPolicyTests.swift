//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

struct RegroupPolicyTests {
    private let spinner = PaginationIndicatorRoomTimelineItem(position: .start).id.uniqueID
    /// Local echoes have a transaction ID; everything else that's sent has an event ID.
    private let a = TimelineItemIdentifier.event(uniqueID: .init("a"), eventOrTransactionID: .eventID("$a"))
    private let b = TimelineItemIdentifier.event(uniqueID: .init("b"), eventOrTransactionID: .eventID("$b"))
    private let echo1 = TimelineItemIdentifier.event(uniqueID: .init("echo1"), eventOrTransactionID: .transactionID("txn1"))
    private let echo2 = TimelineItemIdentifier.event(uniqueID: .init("echo2"), eventOrTransactionID: .transactionID("txn2"))
    
    // MARK: - Cause
    
    @Test(arguments: [false, true])
    func olderItemsArrivingAtTheStartIsBackPagination(isSendInFlight: Bool) {
        #expect(RegroupPolicy.cause(oldIDs: [spinner] + ids("day1", "a", "b"),
                                    newIDs: [spinner] + ids("day0", "x", "y", "day1", "a", "b"),
                                    isSendInFlight: isSendInFlight) == .backPagination)
    }
    
    @Test
    func aPageThatRemovesTheSpinnerIsBackPagination() {
        #expect(RegroupPolicy.cause(oldIDs: [spinner] + ids("day1", "a", "b"),
                                    newIDs: ids("day0", "x", "day1", "a", "b"),
                                    isSendInFlight: false) == .backPagination)
    }
    
    @Test
    func aPageThatReplacesTheTopDateDividerIsBackPagination() {
        #expect(RegroupPolicy.cause(oldIDs: [spinner] + ids("day1", "a", "b"),
                                    newIDs: ids("day0", "x", "a", "b"),
                                    isSendInFlight: false) == .backPagination)
    }
    
    @Test
    func theSpinnerComingOrGoingIsNotAPage() {
        #expect(RegroupPolicy.cause(oldIDs: ids("day1", "a", "b"), newIDs: [spinner] + ids("day1", "a", "b"), isSendInFlight: false) == .other)
        #expect(RegroupPolicy.cause(oldIDs: [spinner] + ids("day1", "a", "b"), newIDs: ids("day1", "a", "b"), isSendInFlight: false) == .other)
    }
    
    @Test
    func aNewNewestItemIsANewestInsert() {
        #expect(RegroupPolicy.cause(oldIDs: ids("a", "b"), newIDs: ids("a", "b", "c"), isSendInFlight: false) == .newestInsert)
    }
    
    @Test
    func aNewNewestItemDuringASendIsAnInsertDuringSend() {
        #expect(RegroupPolicy.cause(oldIDs: ids("a", "b"), newIDs: ids("a", "b", "c"), isSendInFlight: true) == .insertDuringSend)
        #expect(RegroupPolicy.cause(oldIDs: ids("a", "b"), newIDs: ids("a", "b", "day2", "echo"), isSendInFlight: true) == .insertDuringSend)
    }
    
    /// A reaction removed or a sender header gained changes a row, not the IDs.
    @Test(arguments: [false, true])
    func inPlaceChangesAreOther(isSendInFlight: Bool) {
        #expect(RegroupPolicy.cause(oldIDs: ids("a", "b"), newIDs: ids("a", "b"), isSendInFlight: isSendInFlight) == .other)
    }
    
    @Test(arguments: [false, true])
    func aRemovedReadMarkerIsOther(isSendInFlight: Bool) {
        #expect(RegroupPolicy.cause(oldIDs: ids("a", "readMarker", "b"), newIDs: ids("a", "b"), isSendInFlight: isSendInFlight) == .other)
    }
    
    @Test
    func aRemovedNewestItemIsOther() {
        #expect(RegroupPolicy.cause(oldIDs: ids("a", "b", "c"), newIDs: ids("a", "b"), isSendInFlight: false) == .other)
    }
    
    @Test
    func theFirstAndAnEmptySnapshotAreOther() {
        #expect(RegroupPolicy.cause(oldIDs: [], newIDs: ids("a"), isSendInFlight: false) == .other)
        #expect(RegroupPolicy.cause(oldIDs: ids("a"), newIDs: [], isSendInFlight: false) == .other)
    }
    
    // MARK: - Animation
    
    @Test(arguments: [(RegroupPolicy.Cause.newestInsert, true),
                      (.backPagination, false),
                      (.insertDuringSend, false),
                      (.other, false)])
    func onlyAnimatedInsertsAnimateGroupChanges(cause: RegroupPolicy.Cause, animates: Bool) {
        #expect(RegroupPolicy.animatesGroupStyleChange(for: cause) == animates)
    }
    
    @Test
    func insertDuringASendNeverAnimates() {
        #expect(!RegroupPolicy.animatesGroupStyleChange(for: .insertDuringSend))
    }
    
    @Test(arguments: [RegroupPolicy.Cause.backPagination, .insertDuringSend, .other])
    func anUnanimatedUpdateResizesWithoutAnimationOnlyWhenItTogglesASenderHeader(cause: RegroupPolicy.Cause) {
        #expect(!RegroupPolicy.animatesResizes(for: cause, togglesSenderDetails: true))
        #expect(RegroupPolicy.animatesResizes(for: cause, togglesSenderDetails: false))
    }
    
    @Test(arguments: [false, true])
    func anAnimatedInsertAlwaysAnimatesItsResizes(togglesSenderDetails: Bool) {
        #expect(RegroupPolicy.animatesResizes(for: .newestInsert, togglesSenderDetails: togglesSenderDetails))
    }
    
    // MARK: - Send window
    
    @Test(arguments: [false, true])
    func aSendIsInFlightUntilItsComposerClearsAndItsEchoLands(clearFirst: Bool) {
        var window = RegroupPolicy.SendWindow()
        #expect(!window.isOpen(at: 0))
        
        window.sendBegan(at: 0)
        if clearFirst {
            window.composerCleared(at: 0.2)
            #expect(window.isOpen(at: 0.2))
            #expect(update(&window, from: [a], to: [a, echo1], at: 0.3))
        } else {
            #expect(update(&window, from: [a], to: [a, echo1], at: 0.2))
            #expect(window.isOpen(at: 0.2))
            window.composerCleared(at: 0.3)
        }
        
        #expect(!window.isOpen(at: 0.3))
        #expect(!update(&window, from: [a, echo1], to: [a, echo1, b], at: 0.4))
    }
    
    @Test
    func aRapidDoubleSendNeedsBothEchoes() {
        var window = RegroupPolicy.SendWindow()
        window.sendBegan(at: 0)
        window.sendBegan(at: 0.1)
        window.composerCleared(at: 0.2)
        
        #expect(update(&window, from: [a], to: [a, echo1], at: 0.3))
        window.composerCleared(at: 0.35)
        #expect(window.isOpen(at: 0.35))
        #expect(update(&window, from: [a, echo1], to: [a, echo1, echo2], at: 0.45))
        #expect(!window.isOpen(at: 0.45))
    }
    
    @Test
    func bothEchoesInOneUpdateEndTheWindow() {
        var window = RegroupPolicy.SendWindow()
        window.sendBegan(at: 0)
        window.sendBegan(at: 0.1)
        window.composerCleared(at: 0.2)
        window.composerCleared(at: 0.25)
        
        #expect(update(&window, from: [a], to: [a, echo1, echo2], at: 0.3))
        #expect(!window.isOpen(at: 0.3))
    }
    
    @Test
    func aForeignInsertDoesNotEndTheWindow() {
        var window = RegroupPolicy.SendWindow()
        window.sendBegan(at: 0)
        window.composerCleared(at: 0.1)
        
        #expect(update(&window, from: [a], to: [a, b], at: 0.2))
        #expect(window.isOpen(at: 0.2))
        #expect(update(&window, from: [a, b], to: [a, b, echo1], at: 0.3))
        #expect(!window.isOpen(at: 0.3))
    }
    
    @Test
    func anEchoIsOnlyCountedWhenItLands() {
        var window = RegroupPolicy.SendWindow()
        window.sendBegan(at: 0)
        window.sendBegan(at: 0.05)
        window.composerCleared(at: 0.1)
        window.composerCleared(at: 0.15)
        #expect(update(&window, from: [a], to: [a, echo1], at: 0.2))
        
        // The first echo is acknowledged in place, and history arrives above it.
        #expect(update(&window, from: [a, echo1], to: [b, a, echo1], at: 0.3))
        #expect(window.isOpen(at: 0.3))
    }
    
    @Test
    func aLateEchoInsideTheHoldIsStillDuringTheSend() {
        var window = RegroupPolicy.SendWindow()
        window.sendBegan(at: 0)
        window.composerCleared(at: 1.4)
        
        #expect(update(&window, from: [a], to: [a, echo1], at: 2.3))
    }
    
    @Test
    func eachClearExtendsTheWindowByTheEchoWait() {
        var window = RegroupPolicy.SendWindow()
        window.sendBegan(at: 0)
        window.sendBegan(at: 1.4)
        window.composerCleared(at: 2.8)
        window.composerCleared(at: 3.7)
        
        #expect(update(&window, from: [a], to: [a, echo1], at: 4.6))
        #expect(!window.isOpen(at: 3.7 + RegroupPolicy.SendWindow.echoTimeout))
    }
    
    @Test
    func aStaleSendNoLongerCountsAsInFlight() {
        let limit = RegroupPolicy.SendWindow.clearTimeout + RegroupPolicy.SendWindow.echoTimeout
        var window = RegroupPolicy.SendWindow()
        window.sendBegan(at: 100)
        
        #expect(window.isOpen(at: 100 + limit - 0.1))
        #expect(!window.isOpen(at: 100 + limit))
        #expect(!update(&window, from: [a], to: [a, b], at: 100 + limit))
    }
    
    @Test
    func anExpiredSendDoesNotHoldTheNextOneOpen() {
        var window = RegroupPolicy.SendWindow()
        window.sendBegan(at: 0)
        
        window.sendBegan(at: 10)
        window.composerCleared(at: 10.1)
        #expect(update(&window, from: [a], to: [a, echo1], at: 10.2))
        #expect(!window.isOpen(at: 10.2))
    }
    
    // MARK: - Helpers
    
    private func ids(_ values: String...) -> [TimelineItemIdentifier.UniqueID] {
        values.map { .init($0) }
    }
    
    private func update(_ window: inout RegroupPolicy.SendWindow,
                        from oldIDs: [TimelineItemIdentifier],
                        to newIDs: [TimelineItemIdentifier],
                        at now: TimeInterval) -> Bool {
        window.updateArrived(oldIDs: oldIDs.map(\.uniqueID), newIDs: newIDs, at: now)
    }
}
