//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import MatrixRustSDKMocks
import Testing

@MainActor
struct SearchBackfillPlannerTests {
    @Test
    func roomsAreOrderedMostRecentlyActiveFirst() {
        // Given SHUFFLED input, so a pass cannot come from the input already being in order. The room
        // list replays SDK diffs verbatim and applies no app-side sort, so the ordering has to be the
        // planner's own doing.
        let summaries = [makeSummary(id: "!old:server", minutesAgo: 100),
                         makeSummary(id: "!newest:server", minutesAgo: 1),
                         makeSummary(id: "!middle:server", minutesAgo: 50)]
        
        #expect(SearchBackfillPlanner.plan(summaries: summaries, limit: 100) == ["!newest:server", "!middle:server", "!old:server"])
    }
    
    @Test
    func spacesAreExcluded() {
        // A space is a container; it holds no messages to index.
        let summaries = [makeSummary(id: "!space:server", minutesAgo: 1, isSpace: true),
                         makeSummary(id: "!room:server", minutesAgo: 100)]
        
        #expect(SearchBackfillPlanner.plan(summaries: summaries, limit: 100) == ["!room:server"])
    }
    
    @Test
    func tombstonedRoomsAreExcluded() {
        // An upgraded room's history is frozen and lives under the predecessor's ID, so paginating
        // the successor spends network and returns nothing worth indexing.
        let summaries = [makeSummary(id: "!upgraded:server", minutesAgo: 1, isTombstoned: true),
                         makeSummary(id: "!room:server", minutesAgo: 100)]
        
        #expect(SearchBackfillPlanner.plan(summaries: summaries, limit: 100) == ["!room:server"])
    }
    
    @Test
    func invitesAndKnocksAreExcluded() {
        let summaries = [makeSummary(id: "!invited:server", minutesAgo: 1, joinRequestType: .invite(inviter: nil)),
                         makeSummary(id: "!knocked:server", minutesAgo: 2, joinRequestType: .knock),
                         makeSummary(id: "!joined:server", minutesAgo: 100)]
        
        #expect(SearchBackfillPlanner.plan(summaries: summaries, limit: 100) == ["!joined:server"])
    }
    
    @Test
    func roomsWithNoLastMessageAreExcluded() {
        // Nothing has ever arrived here, so there is no history to walk back into.
        let summaries = [makeSummary(id: "!empty:server", minutesAgo: nil),
                         makeSummary(id: "!room:server", minutesAgo: 100)]
        
        #expect(SearchBackfillPlanner.plan(summaries: summaries, limit: 100) == ["!room:server"])
    }
    
    @Test
    func theQueueIsTruncatedToTheLimitKeepingTheMostRecent() {
        let summaries = (1...120).map { makeSummary(id: "!room\($0):server", minutesAgo: Double($0)) }
        
        let plan = SearchBackfillPlanner.plan(summaries: summaries, limit: 100)
        
        #expect(plan.count == 100)
        // Lowest minutes-ago is the most recent, so room 1 leads and the oldest 20 are dropped.
        #expect(plan.first == "!room1:server")
        #expect(!plan.contains("!room120:server"))
    }
    
    @Test
    func duplicateRoomsAppearOnlyOnce() {
        // The room list can momentarily carry the same room twice while diffs settle, and paginating
        // it twice in one generation would pay for the same history two times over.
        let summaries = [makeSummary(id: "!room:server", minutesAgo: 1),
                         makeSummary(id: "!room:server", minutesAgo: 2)]
        
        #expect(SearchBackfillPlanner.plan(summaries: summaries, limit: 100) == ["!room:server"])
    }
    
    @Test
    func anEmptyRoomListYieldsAnEmptyPlan() {
        #expect(SearchBackfillPlanner.plan(summaries: [], limit: 100).isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSummary(id: String,
                             minutesAgo: Double?,
                             isSpace: Bool = false,
                             isTombstoned: Bool = false,
                             joinRequestType: RoomSummary.JoinRequestType? = nil) -> RoomSummary {
        RoomSummary(room: RoomSDKMock(),
                    id: id,
                    joinRequestType: joinRequestType,
                    name: id,
                    isDirect: false,
                    isSpace: isSpace,
                    avatarURL: nil,
                    heroes: [],
                    activeMembersCount: 0,
                    lastMessage: nil,
                    lastMessageDate: minutesAgo.map { Date(timeIntervalSinceReferenceDate: 1_000_000 - $0 * 60) },
                    lastMessageState: nil,
                    unreadMessagesCount: 0,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: nil,
                    canonicalAlias: nil,
                    alternativeAliases: [],
                    hasOngoingCall: false,
                    activeCallIntent: nil,
                    isMarkedUnread: false,
                    isFavourite: false,
                    isTombstoned: isTombstoned)
    }
}
