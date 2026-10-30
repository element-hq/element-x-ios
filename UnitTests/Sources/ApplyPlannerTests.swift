//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

struct ApplyPlannerTests {
    @Test
    func aLiveNewestInsertAnimatesAndResizesThePreviousNewestInItsBatch() {
        let plan = ApplyPlanner.plan(for: input(old: ids(1, 0), new: ids(2, 1, 0)))
        #expect(plan == .init(animated: true, resizedInSameBatchIDs: ids(1), fadeInIDs: []))
    }
    
    @Test
    func aPreviousNewestThatIsGoneIsNotResized() {
        let plan = ApplyPlanner.plan(for: input(old: ids(1, 0), new: ids(2, 0)))
        #expect(plan == .init(animated: true, resizedInSameBatchIDs: [], fadeInIDs: []))
    }
    
    @Test
    func ownEchoesFadeIn() {
        let plan = ApplyPlanner.plan(for: input(old: ids(1, 0), new: ids(2, 1, 0), localEchoes: ids(2)))
        #expect(plan.fadeInIDs == ids(2))
    }
    
    @Test
    func aPendingEchoDoesNotFadeAgainWhenAForeignRowLands() {
        let plan = ApplyPlanner.plan(for: input(old: ids(1, 0), new: ids(2, 1, 0), localEchoes: ids(1)))
        #expect(plan.fadeInIDs.isEmpty)
    }
    
    @Test
    func underReduceMotionNothingFades() {
        let plan = ApplyPlanner.plan(for: input(old: ids(1, 0), new: ids(2, 1, 0), localEchoes: ids(2), reduceMotion: true))
        #expect(plan.fadeInIDs.isEmpty)
    }
    
    @Test
    func whileHoldingTheApplyIsUnanimatedButThePreviousNewestStillResizesInItsBatchAndTheEchoFades() {
        let plan = ApplyPlanner.plan(for: input(old: ids(1, 0), new: ids(2, 1, 0), localEchoes: ids(2), isHoldingSend: true))
        #expect(plan == .init(animated: false, resizedInSameBatchIDs: ids(1), fadeInIDs: ids(2)))
    }
    
    @Test
    func whileHoldingAnUpdateThatKeepsTheNewestResizesNothing() {
        let plan = ApplyPlanner.plan(for: input(old: ids(1, 0), new: ids(1, 0, -1), isHoldingSend: true))
        #expect(plan == .init(animated: false, resizedInSameBatchIDs: [], fadeInIDs: []))
    }
    
    @Test
    func backPaginationIsUnanimated() {
        let plan = ApplyPlanner.plan(for: input(old: ids(1, 0), new: ids(1, 0, -1)))
        #expect(plan == .init(animated: false, resizedInSameBatchIDs: [], fadeInIDs: []))
    }
    
    @Test
    func emptyingTheTimelineIsUnanimated() {
        let plan = ApplyPlanner.plan(for: input(old: ids(1, 0), new: []))
        #expect(plan == .init(animated: false, resizedInSameBatchIDs: [], fadeInIDs: []))
    }
    
    @Test
    func openingARoomIsUnanimated() {
        #expect(!ApplyPlanner.plan(for: input(old: [], new: ids(1, 0))).animated)
    }
    
    @Test
    func detachedOrSwitchingTimelinesAreUnanimated() {
        #expect(!ApplyPlanner.plan(for: input(old: ids(0), new: ids(1, 0), isLive: false)).animated)
        #expect(!ApplyPlanner.plan(for: input(old: ids(0), new: ids(1, 0), isSwitchingTimelines: true)).animated)
    }
    
    /// Pending or failed sends keep their transaction ID, so they can be the newest items when a room opens.
    @Test
    func echoesDoNotFadeInWhenTheApplyIsUnanimated() {
        let unanimatedApplies = [input(old: [], new: ids(1, 0), localEchoes: ids(1)),
                                 input(old: ids(0), new: ids(1, 0), localEchoes: ids(1), isLive: false),
                                 input(old: ids(0), new: ids(1, 0), localEchoes: ids(1), isSwitchingTimelines: true)]
        for input in unanimatedApplies {
            #expect(ApplyPlanner.plan(for: input) == .init(animated: false, resizedInSameBatchIDs: [], fadeInIDs: []))
        }
    }
    
    // MARK: - Helpers
    
    private func ids(_ indices: Int...) -> [TimelineItemIdentifier.UniqueID] {
        indices.map { .init("\($0)") }
    }
    
    private func input(old: [TimelineItemIdentifier.UniqueID],
                       new: [TimelineItemIdentifier.UniqueID],
                       localEchoes: [TimelineItemIdentifier.UniqueID] = [],
                       isLive: Bool = true,
                       isSwitchingTimelines: Bool = false,
                       isHoldingSend: Bool = false,
                       reduceMotion: Bool = false) -> ApplyPlanner.Input {
        .init(oldIDs: old, newIDs: new, localEchoIDs: Set(localEchoes), isLive: isLive,
              isSwitchingTimelines: isSwitchingTimelines, isHoldingSend: isHoldingSend, reduceMotion: reduceMotion)
    }
}
