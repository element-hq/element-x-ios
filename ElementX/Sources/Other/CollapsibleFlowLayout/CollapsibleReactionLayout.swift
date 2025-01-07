//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//
import SwiftUI

/// A flow layout for reactions that will show a collapse/expand button when the layout wraps over a defined number of rows.
/// It  displays an add more button when there are greater than 0 reactions and always displays the reaction and add more button
/// on the same row (moving them both to a new row if necessary).
/// Each subview should be marked with the appropriate `ReactionLayoutItem` using the `reactionLayoutItem` modified
/// so the layout can appropriately treat each type of item.
struct CollapsibleReactionLayout: Layout {
    static let pointOffscreen = CGPoint(x: -10000, y: -10000)
    /// The horizontal spacing between items
    var itemSpacing: CGFloat = 0
    /// The vertical spacing between rows
    var rowSpacing: CGFloat = 0
    /// Whether the layout should display in expanded or collapsed state
    var collapsed = true
    /// The number of rows before the collapse/expand button is shown
    var rowsBeforeCollapsible: Int?
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: some FlowLayoutSubviews, cache: inout ()) -> CGSize {
        guard let subviewsByType = getSubviewsByItemType(subviews: Array(subviews)), subviewsByType.reactions.count > 0 else {
            return .zero
        }
        
        // Calculate the layout of the rows with the reactions button and add more button
        let reactionsAndAddMore = calculateRows(proposal: proposal, subviews: Array(subviewsByType.reactions + [subviewsByType.addMoreButton]))
        // If we have extended beyond the defined number of rows we are showing the expand/collapse ui
        if let rowsBeforeCollapsible, reactionsAndAddMore.count > rowsBeforeCollapsible {
            if collapsed {
                // Truncate to `rowsBeforeCollapsible` number of rows and replace the item at the end of the last row with the button
                let collapsedRows = Array(reactionsAndAddMore.prefix(rowsBeforeCollapsible))
                let (collapsedRowsWithButtons, _) = replaceTrailingItemsWithButtons(rowWidth: proposal.width ?? 0,
                                                                                    rows: collapsedRows,
                                                                                    collapseButton: subviewsByType.collapseButton,
                                                                                    addMoreButton: subviewsByType.addMoreButton)
                let size = sizeThatFits(rows: collapsedRowsWithButtons)
                return size
            } else {
                // Show all subviews with the button at the end
                var rowsWithButtons = calculateRows(proposal: proposal, subviews: Array(subviews))
                ensureCollapseAndAddMoreButtonsAreOnTheSameRow(&rowsWithButtons)
                let size = sizeThatFits(rows: rowsWithButtons)
                return size
            }
        } else {
            // Otherwise we are just calculating the size of all items without the button
            return sizeThatFits(rows: reactionsAndAddMore)
        }
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: some FlowLayoutSubviews, cache: inout ()) {
        guard let subviewsByType = getSubviewsByItemType(subviews: Array(subviews)), subviewsByType.reactions.count > 0 else {
            subviews.forEach { subview in
                subview.place(at: Self.pointOffscreen, anchor: .leading, proposal: .zero)
            }
            return
        }

        // Calculate the layout of the rows with the reactions button and add more button
        let reactionsAndAddMore = calculateRows(proposal: ProposedViewSize(bounds.size), subviews: Array(subviewsByType.reactions + [subviewsByType.addMoreButton]))
        // If we have extended beyond the defined number of rows we are showing the expand/collapse ui
        if let rowsBeforeCollapsible, reactionsAndAddMore.count > rowsBeforeCollapsible {
            if collapsed {
                // Truncate to `rowsBeforeCollapsible` number of rows and replace the item at the end of the last row with the button
                let collapsedRows = Array(reactionsAndAddMore.prefix(rowsBeforeCollapsible))
                let (collapsedRowsWithButtons, subviewsToHide) = replaceTrailingItemsWithButtons(rowWidth: bounds.width,
                                                                                                 rows: collapsedRows,
                                                                                                 collapseButton: subviewsByType.collapseButton,
                                                                                                 addMoreButton: subviewsByType.addMoreButton)
                
                var remainingSubviews = subviewsToHide + Array(reactionsAndAddMore.suffix(reactionsAndAddMore.count - rowsBeforeCollapsible)).joined()
                // remove the add button which was in initial rows calculation
                remainingSubviews.removeLast()
                placeSubviews(in: bounds, rows: collapsedRowsWithButtons)
                // "Remove" (place with a proposed zero frame) any additional subviews
                remainingSubviews.forEach { subview in
                    subview.place(at: Self.pointOffscreen, anchor: .leading, proposal: .zero)
                }
                
            } else {
                // Show all subviews with the buttons at the end
                var rowsWithButtons = calculateRows(proposal: ProposedViewSize(bounds.size), subviews: Array(subviews))
                ensureCollapseAndAddMoreButtonsAreOnTheSameRow(&rowsWithButtons)
                placeSubviews(in: bounds, rows: rowsWithButtons)
            }
        } else {
            // Otherwise we are just placing the reactions and add button
            placeSubviews(in: bounds, rows: reactionsAndAddMore)
            // "Remove"(place with a proposed zero frame) the collapse button
            subviewsByType.collapseButton.place(at: Self.pointOffscreen, anchor: .leading, proposal: .zero)
        }
    }
    
    /// Given a proposed size and a flat list of subviews, calculates and returns a structure representing
    /// how the subviews should wrap on to multiple rows given the size's width.
    /// - Parameters:
    ///   - proposal: The proposed size
    ///   - subviews: The subviews
    /// - Returns: A 2d array, the first dimension representing the rows, the second being the items per row.
    private func calculateRows(proposal: ProposedViewSize, subviews: [FlowLayoutSubview]) -> [[FlowLayoutSubview]] {
        var rows = [[FlowLayoutSubview]]()
        var currentRow = [FlowLayoutSubview]()
        
        var rowX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let horizontalSpacing = currentRow.isEmpty ? 0 : itemSpacing
            // If the current view does not fine on this row bump to the next
            if rowX + size.width > proposal.width ?? 0 {
                rows.append(currentRow)
                currentRow = [LayoutSubview]()
                rowX = 0
            }
            rowX += horizontalSpacing + size.width
            currentRow.append(subview)
        }
        // If there are items in the current row remember to append it to the returned value
        if currentRow.count > 0 {
            rows.append(currentRow)
        }
        return rows
    }
    
    /// Given a list of rows calculate the size needed to display them
    /// - Parameters:
    ///   - proposal: The proposed size
    ///   - rows: The list of rows
    /// - Returns: The size render the rows
    private func sizeThatFits(rows: [[FlowLayoutSubview]]) -> CGSize {
        let sizes = rows.map { row in
            row.map { subview in
                subview.sizeThatFits(.unspecified)
            }
        }
        let maxHeight = sizes.joined().reduce(0) { partialResult, size in
            max(partialResult, size.height)
        }
        
        return sizes.enumerated().reduce(CGSize.zero) { partialResult, rowItem in
            let (rowIndex, row) = rowItem
            let rowSize = row.enumerated().reduce(CGSize.zero) { partialResult, subviewItem in
                let (subviewIndex, size) = subviewItem
                let horizontalSpacing = subviewIndex == 0 ? 0 : itemSpacing
                return CGSize(width: partialResult.width + size.width + horizontalSpacing, height: maxHeight)
            }
            let verticalSpacing = rowIndex == 0 ? 0 : rowSpacing
            return CGSize(width: max(partialResult.width, rowSize.width), height: partialResult.height + rowSize.height + verticalSpacing)
        }
    }
    
    /// Used to render the collapsed state, this takes the rows inputted and adds the button to the last row,
    /// removing only as many trailing subviews as needed to make space for it. It also returns the items removed.
    /// - Parameters:
    ///   - rowWidth: The width of the parent
    ///   - rows: The input list of rows
    ///   - button: The button to replace the trailing items
    /// - Returns: The new rows structure with button replaced and the subviews remove from the input to make space for the button
    private func replaceTrailingItemsWithButtons(rowWidth: CGFloat, rows: [[FlowLayoutSubview]], collapseButton: FlowLayoutSubview, addMoreButton: FlowLayoutSubview) -> ([[FlowLayoutSubview]], [FlowLayoutSubview]) {
        var rows = rows
        let lastRow = rows[rows.count - 1]
        let collapseButtonSize = collapseButton.sizeThatFits(.unspecified)
        let addMoreButtonSize = addMoreButton.sizeThatFits(.unspecified)
        let buttonsWidth = collapseButtonSize.width + itemSpacing + addMoreButtonSize.width
        var rowX: CGFloat = 0
        for (i, subview) in lastRow.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let horizontalSpacing = i == 0 ? 0 : itemSpacing
            rowX += size.width + horizontalSpacing
            if rowX > (rowWidth - (buttonsWidth + horizontalSpacing)) {
                let lastRowWithButton = Array(lastRow.prefix(i)) + [collapseButton, addMoreButton]
                let subviewsToHide = Array(lastRow.suffix(lastRow.count - i))
                rows[rows.count - 1] = lastRowWithButton
                return (rows, subviewsToHide)
            }
        }
        let lastRowWithButton = Array(lastRow) + [collapseButton, addMoreButton]
        rows[rows.count - 1] = lastRowWithButton
        return (rows, [])
    }
    
    private func ensureCollapseAndAddMoreButtonsAreOnTheSameRow(_ rows: inout [[FlowLayoutSubview]]) {
        guard var lastRow = rows.last, lastRow.count == 1 else {
            return
        }
        var secondLastRow = rows[rows.count - 2]
        let collapseButton = secondLastRow.removeLast()
        lastRow.insert(collapseButton, at: 0)
        rows[rows.count - 2] = secondLastRow
        rows[rows.count - 1] = lastRow
    }
    
    /// Given a list of rows place them in the layout.
    /// - Parameters:
    ///   - bounds: The bounds of the parent
    ///   - rows: The input row structure.
    private func placeSubviews(in bounds: CGRect, rows: [[FlowLayoutSubview]]) {
        var rowY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        let sizes = rows.map { row in
            row.map { subview in
                subview.sizeThatFits(.unspecified)
            }
        }
        
        let maxHeight = sizes.joined().reduce(0) { partialResult, size in
            max(partialResult, size.height)
        }
        
        for (i, row) in sizes.enumerated() {
            var rowX: CGFloat = bounds.minX
            let verticalSpacing = i == 0 ? 0 : rowSpacing
            for (j, size) in row.enumerated() {
                let subview = rows[i][j]
                let horizontalSpacing = j == 0 ? 0 : itemSpacing
                let point = CGPoint(x: rowX + horizontalSpacing, y: rowY + verticalSpacing + (maxHeight / 2))
                subview.place(at: point, anchor: .leading, proposal: ProposedViewSize(CGSize(width: size.width, height: maxHeight)))
                rowHeight = max(rowHeight, maxHeight)
                rowX += size.width + horizontalSpacing
            }
            rowY += rowHeight + verticalSpacing
        }
    }
    
    /// Group the subviews by type using `ReactionLayoutItemType`
    /// - Parameter subviews: A flat list of all the subviews
    /// - Returns: The subviews organised by type
    private func getSubviewsByItemType(subviews: [FlowLayoutSubview]) -> ReactionSubviews? {
        var collapseButton: FlowLayoutSubview?
        var addMoreButton: FlowLayoutSubview?
        var reactions: [FlowLayoutSubview] = []
        for subview in subviews {
            switch subview[ReactionLayoutItemType.self] {
            case .reaction:
                reactions.append(subview)
            case .expandCollapse:
                collapseButton = subview
            case .addMore:
                addMoreButton = subview
            }
        }
        guard let collapseButton, let addMoreButton, reactions.count > 0 else {
            return nil
        }
        return ReactionSubviews(reactions: reactions, collapseButton: collapseButton, addMoreButton: addMoreButton)
    }
}

struct ReactionSubviews {
    var reactions: [FlowLayoutSubview]
    var collapseButton: FlowLayoutSubview
    var addMoreButton: FlowLayoutSubview
}

/// A protocol representing subviews so that we can inject mocks in unit tests.
protocol FlowLayoutSubviews: RandomAccessCollection where Element: FlowLayoutSubview, Index == Int, SubSequence == Self { }

extension LayoutSubviews: FlowLayoutSubviews { }

/// A protocol representing a subview so that we can inject mocks in unit tests.
protocol FlowLayoutSubview {
    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize
    func place(at position: CGPoint, anchor: UnitPoint, proposal: ProposedViewSize)
    subscript<K>(key: K.Type) -> K.Value where K: LayoutValueKey { get }
}

extension LayoutSubview: FlowLayoutSubview { }

enum ReactionLayoutItem {
    case reaction
    case expandCollapse
    case addMore
}

struct ReactionLayoutItemType: LayoutValueKey {
    static let defaultValue: ReactionLayoutItem = .reaction
}

extension View {
    func reactionLayoutItem(_ value: ReactionLayoutItem) -> some View {
        layoutValue(key: ReactionLayoutItemType.self, value: value)
    }
}
