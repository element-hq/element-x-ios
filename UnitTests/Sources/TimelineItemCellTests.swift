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
    /// A row taller than its content, as when a resize hasn't reached the row yet.
    @Test
    func contentIsCentredInAStaleRowUnlessItsPendingChangeIsBeingLaidOut() throws {
        let host = try BubbleTableHost()
        let centredOffset = (BubbleTableHost.rowHeight - BubbleTableHost.bubbleHeight - BubbleTableHost.receiptHeight) / 2
        #expect(abs(host.bubbleOffsetFromTheTopOfTheNewestRow() - centredOffset) < 0.5)
        
        let cell = try #require(host.newestCell())
        cell.layOutPendingContentChange()
        #expect(abs(host.bubbleOffsetFromTheTopOfTheNewestRow()) < 0.5)
        
        cell.finishPendingContentChange()
        cell.contentView.setNeedsLayout()
        cell.contentView.layoutIfNeeded()
        #expect(abs(host.bubbleOffsetFromTheTopOfTheNewestRow() - centredOffset) < 0.5, "The content should be centred again.")
    }
}

/// A flipped table, as in the timeline, whose 200 pt rows show a 60 pt bubble through `TimelineItemCell.setContent` and,
/// for the newest row only, a 20 pt receipt below it.
private final class BubbleTableHost {
    static let rowHeight: CGFloat = 200
    static let bubbleHeight: CGFloat = 60
    static let receiptHeight: CGFloat = 20
    
    private let window: UIWindow
    private let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 390, height: 700), style: .plain)
    private var dataSource: UITableViewDiffableDataSource<Int, Int>?
    private let newestFirstRows = [1, 0]
    private var bubbles: [Int: UIView] = [:]
    
    init() throws {
        let scene = try #require(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        window = UIWindow(windowScene: scene)
        
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        tableView.register(TimelineItemCell.self, forCellReuseIdentifier: TimelineItemCell.reuseIdentifier)
        tableView.separatorStyle = .none
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        tableView.rowHeight = Self.rowHeight
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, row in
            let cell = tableView.dequeueReusableCell(withIdentifier: TimelineItemCell.reuseIdentifier, for: indexPath)
            guard let self, let cell = cell as? TimelineItemCell else { return cell }
            let bubble = UIView()
            bubbles[row] = bubble
            let isNewest = row == newestFirstRows.first
            cell.setContent {
                BubbleWithReceipt(isNewest: isNewest, bubble: bubble)
            }
            return cell
        }
        window.addSubview(tableView)
        window.isHidden = false
        
        applyRows()
        tableView.layoutIfNeeded()
    }
    
    isolated deinit {
        window.isHidden = true
    }
    
    func newestCell() -> TimelineItemCell? {
        tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TimelineItemCell
    }
    
    func bubbleOffsetFromTheTopOfTheNewestRow() -> CGFloat {
        guard let bubble = bubbles[newestFirstRows[0]] else { return .nan }
        let rowTop = tableView.convert(tableView.rectForRow(at: IndexPath(row: 0, section: 0)), to: window).minY
        return bubble.convert(bubble.bounds, to: window).minY - rowTop
    }
    
    private func applyRows() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(newestFirstRows)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}

private struct BubbleWithReceipt: View {
    let isNewest: Bool
    let bubble: UIView
    
    var body: some View {
        VStack(spacing: 0) {
            Probe(view: bubble)
                .frame(height: BubbleTableHost.bubbleHeight)
            if isNewest {
                Color.blue.frame(height: BubbleTableHost.receiptHeight)
            }
        }
    }
}

private struct Probe: UIViewRepresentable {
    let view: UIView
    
    func makeUIView(context: Context) -> UIView {
        view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) { }
}
