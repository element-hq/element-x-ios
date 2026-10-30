//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

struct AnchorPolicyTests {
    @Test
    func topEdgePrefersTheTopmostRow() {
        let anchors = AnchorPolicy.anchors(in: geometry([.message, .message, .message]), nearest: .top)
        #expect(anchors.map(\.id) == ids(0, 1, 2))
        #expect(anchors.map(\.visualTop) == [0, 50, 100])
    }
    
    @Test
    func bottomEdgePrefersTheBottommostRow() {
        let anchors = AnchorPolicy.anchors(in: geometry([.message, .message, .message]), nearest: .bottom)
        #expect(anchors.map(\.id) == ids(2, 1, 0))
        #expect(anchors.map(\.visualTop) == [100, 50, 0])
    }
    
    @Test
    func decorationsCanBeAnchors() {
        let rows = geometry([.decoration, .message])
        #expect(AnchorPolicy.anchors(in: rows, nearest: .top).map(\.id) == ids(0, 1))
        #expect(AnchorPolicy.anchors(in: rows, nearest: .bottom).map(\.id) == ids(1, 0))
    }
    
    @Test(arguments: [TimelineGeometry.Row.Kind.paginationIndicator, .group, .readMarker])
    func rowsThatChangeAroundPaginationAreSkipped(kind: TimelineGeometry.Row.Kind) {
        #expect(AnchorPolicy.anchors(in: geometry([kind, .message]), nearest: .top).map(\.id) == ids(1))
        #expect(AnchorPolicy.anchors(in: geometry([.message, kind]), nearest: .bottom).map(\.id) == ids(0))
    }
    
    @Test
    func rowsChangingInThisUpdateAreSkipped() {
        let rows = geometry([.message, .message])
        #expect(AnchorPolicy.anchors(in: rows, nearest: .top, excluding: [id(0)]).map(\.id) == ids(1))
        #expect(AnchorPolicy.anchors(in: rows, nearest: .bottom, excluding: [id(1)]).map(\.id) == ids(0))
    }
    
    @Test(arguments: [AnchorPolicy.Edge.top, .bottom])
    func nothingAnchorableGivesNoAnchors(edge: AnchorPolicy.Edge) {
        #expect(AnchorPolicy.anchors(in: geometry([]), nearest: edge).isEmpty)
        #expect(AnchorPolicy.anchors(in: geometry([.paginationIndicator, .group, .readMarker]), nearest: edge).isEmpty)
        #expect(AnchorPolicy.anchors(in: geometry([.message, .decoration]), nearest: edge, excluding: [id(0), id(1)]).isEmpty)
    }
    
    @Test
    func correctionIsHowFarTheAnchorMoved() {
        let anchor = AnchorPolicy.Anchor(id: id(0), visualTop: 100)
        #expect(AnchorPolicy.correction(for: anchor, newVisualTop: 130) == 30)
        #expect(AnchorPolicy.correction(for: anchor, newVisualTop: 80) == -20)
    }
    
    @Test(arguments: [AnchorPolicy.Edge.top, .bottom])
    func theChosenAnchorStaysPutWhenAPageLands(edge: AnchorPolicy.Edge) throws {
        var generator = SeededGenerator(seed: 42)
        var edgeAnchorRegroupedRuns = 0
        
        for _ in 0..<500 {
            let before = randomGeometry(using: &generator)
            let regroupedIDs = Set(before.rows.map(\.id).filter { _ in Bool.random(using: &generator) })
            
            let anchors = AnchorPolicy.anchors(in: before, nearest: edge, excluding: regroupedIDs)
            
            // Written out by hand rather than through `isAnchorable`, so the test doesn't share the rule it checks.
            let candidates = (edge == .top ? before.rows : before.rows.reversed())
                .filter { [TimelineGeometry.Row.Kind.message, .decoration].contains($0.kind) }
            let expected = candidates
                .filter { !regroupedIDs.contains($0.id) }
                .map { AnchorPolicy.Anchor(id: $0.id, visualTop: $0.visualTop) }
            #expect(anchors == expected)
            
            guard let anchor = anchors.first else { continue }
            if let edgeCandidate = candidates.first, regroupedIDs.contains(edgeCandidate.id) {
                edgeAnchorRegroupedRuns += 1
            }
            
            let after = landPage(on: before, regrouping: regroupedIDs, using: &generator)
            let original = try #require(before.rows.first { $0.id == anchor.id })
            let moved = try #require(after.rows.first { $0.id == anchor.id })
            
            let correction = AnchorPolicy.correction(for: anchor, newVisualTop: moved.visualTop)
            
            // Only a row that kept its height lines up at the bottom too, so this catches a regrouped or self-resizing anchor.
            #expect(abs(moved.visualTop - correction - original.visualTop) < 0.001)
            #expect(abs(moved.visualBottom - correction - original.visualBottom) < 0.001)
        }
        
        // The spec's case: the row that would have been the anchor regroups, so another row keeps the reader's place.
        #expect(edgeAnchorRegroupedRuns > 0)
    }
    
    @Test
    func rowKindFollowsTheTimelineItemType() {
        let text = TextRoomTimelineItem(id: .virtual(uniqueID: id(0)),
                                        timestamp: .mock,
                                        isOutgoing: false,
                                        isEditable: false,
                                        canBeRepliedTo: true,
                                        sender: .init(id: "@sender:example.com"),
                                        content: .init(body: "Test message"))
        
        #expect(TimelineGeometry.Row.Kind(.text(text)) == .message)
        #expect(TimelineGeometry.Row.Kind(.paginationIndicator(.init(position: .start))) == .paginationIndicator)
        #expect(TimelineGeometry.Row.Kind(.group(.init(items: [text]))) == .group)
        #expect(TimelineGeometry.Row.Kind(.readMarker(.init(id: .virtual(uniqueID: id(1))))) == .readMarker)
        #expect(TimelineGeometry.Row.Kind(.separator(.init(id: .virtual(uniqueID: id(2)), timestamp: .mock))) == .decoration)
        #expect(TimelineGeometry.Row.Kind(.timelineStart(.init(name: nil))) == .decoration)
    }
    
    // MARK: - Helpers
    
    private func id(_ index: Int) -> TimelineItemIdentifier.UniqueID {
        .init("\(index)")
    }
    
    private func ids(_ indices: Int...) -> [TimelineItemIdentifier.UniqueID] {
        indices.map(id)
    }
    
    private func geometry(_ kinds: [TimelineGeometry.Row.Kind]) -> TimelineGeometry {
        let rows = kinds.enumerated().map { index, kind in
            TimelineGeometry.Row(id: id(index), kind: kind, visualTop: CGFloat(index) * 50, visualBottom: CGFloat(index + 1) * 50)
        }
        return TimelineGeometry(rows: rows, viewportBottom: 600, viewportHeight: 600)
    }
    
    /// Up to 8 rows of random kinds and heights, stacked from a random top.
    private func randomGeometry(using generator: inout SeededGenerator) -> TimelineGeometry {
        let kinds: [TimelineGeometry.Row.Kind] = [.message, .message, .decoration, .paginationIndicator, .group, .readMarker]
        let rows = (0..<Int.random(in: 0...8, using: &generator)).map { index in
            row(id: id(index),
                kind: kinds[Int.random(in: kinds.indices, using: &generator)],
                height: .random(in: 44...200, using: &generator))
        }
        return stack(rows, from: .random(in: 0...100, using: &generator))
    }
    
    /// Lands a page of new rows at a random edge and lays every row out again from a new top, so every row moves.
    /// Regrouped rows change height, and so do the kinds that resize on their own (spinners, groups, the read marker).
    private func landPage(on geometry: TimelineGeometry,
                          regrouping regroupedIDs: Set<TimelineItemIdentifier.UniqueID>,
                          using generator: inout SeededGenerator) -> TimelineGeometry {
        let resizingKinds: [TimelineGeometry.Row.Kind] = [.paginationIndicator, .group, .readMarker]
        let rows = geometry.rows.map { existing in
            guard regroupedIDs.contains(existing.id) || resizingKinds.contains(existing.kind) else { return existing }
            // Never 0, so a wrong anchor always shows up at its bottom edge.
            let change = CGFloat.random(in: 8...40, using: &generator) * (Bool.random(using: &generator) ? 1 : -1)
            return row(id: existing.id, kind: existing.kind, height: existing.visualBottom - existing.visualTop + change)
        }
        let page = (0..<Int.random(in: 1...4, using: &generator)).map { index in
            row(id: .init("page-\(index)"), kind: .message, height: .random(in: 44...200, using: &generator))
        }
        let pageLandsAtTheTop = Bool.random(using: &generator)
        return stack(pageLandsAtTheTop ? page + rows : rows + page, from: .random(in: -400...400, using: &generator))
    }
    
    private func row(id: TimelineItemIdentifier.UniqueID, kind: TimelineGeometry.Row.Kind, height: CGFloat) -> TimelineGeometry.Row {
        TimelineGeometry.Row(id: id, kind: kind, visualTop: 0, visualBottom: height)
    }
    
    /// Lays the rows out top to bottom from `top`, keeping each row's height.
    private func stack(_ rows: [TimelineGeometry.Row], from top: CGFloat) -> TimelineGeometry {
        var stacked: [TimelineGeometry.Row] = []
        var bottom = top
        for row in rows {
            let height = row.visualBottom - row.visualTop
            stacked.append(TimelineGeometry.Row(id: row.id, kind: row.kind, visualTop: bottom, visualBottom: bottom + height))
            bottom += height
        }
        return TimelineGeometry(rows: stacked, viewportBottom: bottom, viewportHeight: bottom - top)
    }
}

/// A deterministic random number generator so seeded property tests are repeatable.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        state = seed
    }
    
    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}
