//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Moves the timeline's rows and keeps its offset range wide enough for them, so UIKit never clamps a move. The table's
/// controller still writes the offset itself where a clamp can't happen or is wanted, such as the bottom rest and the
/// send hold's release. Positions are window coordinates, and "visual" means as seen on screen: the table is flipped,
/// so a row's visual top is its rect's max y.
struct FlippedTableScroller {
    let tableView: UITableView
    
    func visualTop(of indexPath: IndexPath) -> CGFloat {
        let rect = tableView.rectForRow(at: indexPath)
        return tableView.convert(CGPoint(x: 0, y: rect.maxY), to: nil).y
    }
    
    /// Moves the rows down on screen by `delta` (up when negative) without animation, keeping any deceleration going.
    /// A `bounds` write doesn't call `scrollViewDidScroll`: callers refresh whatever they derive from scrolling.
    @discardableResult
    func moveRowsVisually(by delta: CGFloat) -> UIEdgeInsets {
        guard abs(delta) >= 0.5 else { return .zero }
        var added = UIEdgeInsets.zero
        UIView.performWithoutAnimation {
            // Rows move down as the offset grows in the flipped table.
            let offset = tableView.contentOffset.y + delta
            added = widenInsets(toAllow: offset)
            tableView.bounds.origin.y = offset
        }
        return added
    }
    
    /// UIKit clamps an out-of-range offset on inset writes, content-size changes and frame changes, so the range is widened first.
    /// - Parameter height: The table's height once a resize about to happen has, if not its current one.
    @discardableResult
    func widenInsets(toAllow offset: CGFloat, height: CGFloat? = nil) -> UIEdgeInsets {
        let range = offsetRange(height: height)
        var added = UIEdgeInsets.zero
        if offset < range.lowerBound {
            added.top = range.lowerBound - offset
        }
        if offset > range.upperBound {
            // Measured from where the rows end, not from the range's end: when they don't fill the table, the range ends where it starts.
            added.bottom = offset - rowsEndOffset(height: height)
        }
        if added != .zero {
            UIView.performWithoutAnimation {
                tableView.contentInset.top += added.top
                tableView.contentInset.bottom += added.bottom
            }
        }
        return added
    }
    
    /// The offset must be inside the restored range: UIKit clamps one outside it on this write, with a visible jump.
    func removeInsets(_ added: UIEdgeInsets) {
        guard added != .zero else { return }
        UIView.performWithoutAnimation {
            tableView.contentInset.top -= added.top
            tableView.contentInset.bottom -= added.bottom
        }
    }
    
    /// Removes each end of `added` once the offset has left the space it makes there, so unlike `removeInsets`
    /// it never clamps. Nothing goes while the offset is past an end, as in a bounce.
    /// - Returns: What is left of `added`.
    func removeInsetsNoLongerNeeded(from added: UIEdgeInsets) -> UIEdgeInsets {
        let offset = tableView.contentOffset.y
        guard offsetRange().contains(offset) else { return added }
        var kept = added
        if offset >= offsetRange(without: UIEdgeInsets(top: added.top, left: 0, bottom: 0, right: 0)).lowerBound {
            kept.top = 0
        }
        // Measured after the top goes, as that raises the start, which is also the end when the rows don't fill the table.
        if offset <= offsetRange(without: UIEdgeInsets(top: added.top - kept.top, left: 0, bottom: added.bottom, right: 0)).upperBound {
            kept.bottom = 0
        }
        removeInsets(UIEdgeInsets(top: added.top - kept.top, left: 0, bottom: added.bottom - kept.bottom, right: 0))
        return kept
    }
    
    /// The offsets UIKit allows, or would allow without `insets`, or at `height`.
    func offsetRange(without insets: UIEdgeInsets = .zero, height: CGFloat? = nil) -> ClosedRange<CGFloat> {
        let minOffset = insets.top - tableView.adjustedContentInset.top
        return minOffset...max(minOffset, rowsEndOffset(without: insets, height: height))
    }
    
    /// The offset that shows the oldest row at the visual top, which is below the range's start when the rows don't fill the table.
    private func rowsEndOffset(without insets: UIEdgeInsets = .zero, height: CGFloat? = nil) -> CGFloat {
        tableView.contentSize.height + tableView.adjustedContentInset.bottom - insets.bottom - (height ?? tableView.bounds.height)
    }
}

extension UIEdgeInsets {
    nonisolated static func += (lhs: inout UIEdgeInsets, rhs: UIEdgeInsets) {
        lhs = UIEdgeInsets(top: lhs.top + rhs.top, left: lhs.left + rhs.left, bottom: lhs.bottom + rhs.bottom, right: lhs.right + rhs.right)
    }
}
