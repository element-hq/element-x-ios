//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import SwiftUI

/// A flow layout for reactions that will show a collapse/expand button when the layout wraps over a defined number of rows.
/// It  displays an add more button when there are greater than 0 reactions and always displays the reaction and add more button
/// on the same line (moving them both to a new line if necessary).
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
                let size = sizeThatFits(proposal: proposal, rows: collapsedRowsWithButtons)
                return size
            } else {
                // Show all subviews with the button at the end
                var rowsWithButtons = calculateRows(proposal: proposal, subviews: Array(subviews))
                ensureCollapseAndAddMoreButtonsAreOnTheSameLine(&rowsWithButtons)
                let size = sizeThatFits(proposal: proposal, rows: rowsWithButtons)
                return size
            }
        } else {
            // Otherwise we are just calculating the size of all items without the button
            return sizeThatFits(proposal: proposal, rows: reactionsAndAddMore)
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
                ensureCollapseAndAddMoreButtonsAreOnTheSameLine(&rowsWithButtons)
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
        var currentLine = [FlowLayoutSubview]()
        
        var rowX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let hSpacing = currentLine.isEmpty ? 0 : itemSpacing
            // If the current view does not fine on this row bump to the next
            if rowX + size.width > proposal.width ?? 0 {
                rows.append(currentLine)
                currentLine = [LayoutSubview]()
                rowX = 0
            }
            rowX += hSpacing + size.width
            currentLine.append(subview)
        }
        // If there are items in the current line remember to append it to the returned value
        if currentLine.count > 0 {
            rows.append(currentLine)
        }
        return rows
    }
    
    /// Given a list of rows calculate the size needed to display them
    /// - Parameters:
    ///   - proposal: The proposed size
    ///   - rows: The list of rows
    /// - Returns: The size render the rows
    private func sizeThatFits(proposal: ProposedViewSize, rows: [[FlowLayoutSubview]]) -> CGSize {
        rows.enumerated().reduce(CGSize.zero) { partialResult, rowItem in
            let (rowIndex, row) = rowItem
            let rowSize = row.enumerated().reduce(CGSize.zero) { partialResult, subviewItem in
                let (subviewIndex, subview) = subviewItem
                let size = subview.sizeThatFits(.unspecified)
                let hSpacing = subviewIndex == 0 ? 0 : itemSpacing
                return CGSize(width: partialResult.width + size.width + hSpacing, height: max(partialResult.height, size.height))
            }
            let vSpacing = rowIndex == 0 ? 0 : rowSpacing
            return CGSize(width: max(partialResult.width, rowSize.width), height: partialResult.height + rowSize.height + vSpacing)
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
        let lastLine = rows[rows.count - 1]
        let collapseButtonSize = collapseButton.sizeThatFits(.unspecified)
        let addMoreButtonSize = addMoreButton.sizeThatFits(.unspecified)
        let buttonsWidth = collapseButtonSize.width + itemSpacing + addMoreButtonSize.width
        var rowX: CGFloat = 0
        for (i, subview) in lastLine.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let hSpacing = i == 0 ? 0 : itemSpacing
            rowX += size.width + hSpacing
            if rowX > (rowWidth - (buttonsWidth + hSpacing)) {
                let lastLineWithButton = Array(lastLine.prefix(i)) + [collapseButton, addMoreButton]
                let subviewsToHide = Array(lastLine.suffix(lastLine.count - i))
                rows[rows.count - 1] = lastLineWithButton
                return (rows, subviewsToHide)
            }
        }
        let lastLineWithButton = Array(lastLine) + [collapseButton, addMoreButton]
        rows[rows.count - 1] = lastLineWithButton
        return (rows, [])
    }
    
    private func ensureCollapseAndAddMoreButtonsAreOnTheSameLine(_ rows: inout [[FlowLayoutSubview]]) {
        guard var lastLine = rows.last, lastLine.count == 1 else {
            return
        }
        var secondLastLine = rows[rows.count - 2]
        let collapseButton = secondLastLine.removeLast()
        lastLine.prepend(collapseButton)
        rows[rows.count - 2] = secondLastLine
        rows[rows.count - 1] = lastLine
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
            let vSpacing = i == 0 ? 0 : rowSpacing
            for (j, size) in row.enumerated() {
                let subview = rows[i][j]
                let hSpacing = j == 0 ? 0 : itemSpacing
                let point = CGPoint(x: rowX + hSpacing, y: rowY + vSpacing + (maxHeight / 2))
                subview.place(at: point, anchor: .leading, proposal: ProposedViewSize(CGSize(width: size.width, height: maxHeight)))
                rowHeight = max(rowHeight, maxHeight)
                rowX += size.width + hSpacing
            }
            rowY += rowHeight + vSpacing
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
