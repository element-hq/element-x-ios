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

/// A flow layout that will show a collapse/expand button when the layout wraps over a defined number of rows.
/// With n subviews passed to the layout, n-1 first views represent the main views to be laid out.
/// The nth subview is the collapse/expand button which is only shown when the layout overflows `rowsBeforeCollapsible` number of rows.
/// When the button is shown it is tagged on the end of the collapsed or expanded layout.
struct CollapsibleFlowLayout: Layout {
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
        let collapseButton = subviews[subviews.count - 1]
        var subviewsWithoutCollapseButton = subviews
        subviewsWithoutCollapseButton.removeLast()
        // Calculate the layout of the rows without the button
        let rowsNoButton = calculateRows(proposal: proposal, subviews: Array(subviewsWithoutCollapseButton))
        
        // If we have extended beyond the defined number of rows we are showing the expand/collapse ui
        if let rowsBeforeCollapsible, rowsNoButton.count > rowsBeforeCollapsible {
            if collapsed {
                // Truncate to `rowsBeforeCollapsible` number of rows and replace the item at the end of the last row with the button
                let collapsedRows = Array(rowsNoButton.prefix(rowsBeforeCollapsible))
                let (collapsedRowsWithButton, _) = replaceTrailingItemsWithButton(rowWidth: proposal.width ?? 0, rows: collapsedRows, button: collapseButton)
                let size = sizeThatFits(proposal: proposal, rows: collapsedRowsWithButton)
                return size
            } else {
                // Show all subviews with the button at the end
                let rowsWithButton = calculateRows(proposal: proposal, subviews: Array(subviews))
                let size = sizeThatFits(proposal: proposal, rows: rowsWithButton)
                return size
            }
        } else {
            // Otherwise we are just calculating the size of all items without the button
            return sizeThatFits(proposal: proposal, rows: rowsNoButton)
        }
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: some FlowLayoutSubviews, cache: inout ()) {
        let collapseButton = subviews[subviews.count - 1]
        var subviewsWithoutCollapseButton = subviews
        subviewsWithoutCollapseButton.removeLast()
        // Calculate the layout of the rows without the button
        let rowsNoButton = calculateRows(proposal: ProposedViewSize(bounds.size), subviews: Array(subviewsWithoutCollapseButton))
        // If we have extended beyond the defined number of rows we are showing the expand/collapse ui
        if let rowsBeforeCollapsible, rowsNoButton.count > rowsBeforeCollapsible {
            if collapsed {
                // Truncate to `rowsBeforeCollapsible` number of rows and replace the item at the end of the last row with the button
                let collapsedRows = Array(rowsNoButton.prefix(rowsBeforeCollapsible))
                let (collapsedRowsWithButton, subviewsToHide) = replaceTrailingItemsWithButton(rowWidth: bounds.width, rows: collapsedRows, button: collapseButton)
                let remainingSubviews = subviewsToHide + Array(rowsNoButton.suffix(rowsNoButton.count - rowsBeforeCollapsible)).joined()
                placeSubviews(in: bounds, rows: collapsedRowsWithButton)
                // "Remove" (place with a proposed zero frame) any additional subviews
                remainingSubviews.forEach { subview in
                    subview.place(at: Self.pointOffscreen, anchor: .leading, proposal: .zero)
                }
                
            } else {
                // Show all subviews with the button at the end
                let rowsWithButton = calculateRows(proposal: ProposedViewSize(bounds.size), subviews: Array(subviews))
                placeSubviews(in: bounds, rows: rowsWithButton)
            }
        } else {
            // Otherwise we are just calculating the size of all items without the button
            placeSubviews(in: bounds, rows: rowsNoButton)
            // "Remove"(place with a proposed zero frame) the button
            collapseButton.place(at: Self.pointOffscreen, anchor: .leading, proposal: .zero)
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
    private func sizeThatFits(proposal: ProposedViewSize, rows: [[FlowLayoutSubview]]) -> CGSize {
        rows.enumerated().reduce(CGSize.zero) { partialResult, rowItem in
            let (rowIndex, row) = rowItem
            let rowSize = row.enumerated().reduce(CGSize.zero) { partialResult, subviewItem in
                let (subviewIndex, subview) = subviewItem
                let size = subview.sizeThatFits(.unspecified)
                let horizontalSpacing = subviewIndex == 0 ? 0 : itemSpacing
                return CGSize(width: partialResult.width + size.width + horizontalSpacing, height: max(partialResult.height, size.height))
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
    private func replaceTrailingItemsWithButton(rowWidth: CGFloat, rows: [[FlowLayoutSubview]], button: FlowLayoutSubview) -> ([[FlowLayoutSubview]], [FlowLayoutSubview]) {
        var rows = rows
        let lastRow = rows[rows.count - 1]
        let buttonSize = button.sizeThatFits(.unspecified)
        var rowX: CGFloat = 0
        for (i, subview) in lastRow.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let horizontalSpacing = i == 0 ? 0 : itemSpacing
            rowX += size.width + horizontalSpacing
            if rowX > (rowWidth - (buttonSize.width + horizontalSpacing)) {
                let lastRowWithButton = Array(lastRow.prefix(i)) + [button]
                let subviewsToHide = Array(lastRow.suffix(lastRow.count - i))
                rows[rows.count - 1] = lastRowWithButton
                return (rows, subviewsToHide)
            }
        }
        let lastRowWithButton = Array(lastRow) + [button]
        rows[rows.count - 1] = lastRowWithButton
        return (rows, [])
    }
    
    /// Given a list of rows place them in the layout.
    /// - Parameters:
    ///   - bounds: The bounds of the parent
    ///   - rows: The input row structure.
    private func placeSubviews(in bounds: CGRect, rows: [[FlowLayoutSubview]]) {
        var rowY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for (i, row) in rows.enumerated() {
            var rowX: CGFloat = bounds.minX
            let verticalSpacing = i == 0 ? 0 : rowSpacing
            for (j, subview) in row.enumerated() {
                let size = subview.sizeThatFits(.unspecified)
                let horizontalSpacing = j == 0 ? 0 : itemSpacing
                let point = CGPoint(x: rowX + horizontalSpacing, y: rowY + verticalSpacing + (size.height / 2))
                subview.place(at: point, anchor: .leading, proposal: ProposedViewSize(size))
                rowHeight = max(rowHeight, size.height)
                rowX += size.width + horizontalSpacing
            }
            rowY += rowHeight + verticalSpacing
        }
    }
}

/// A protocol representing subviews so that we can inject mocks in unit tests.
protocol FlowLayoutSubviews: RandomAccessCollection where Element: FlowLayoutSubview, Index == Int, SubSequence == Self { }

extension LayoutSubviews: FlowLayoutSubviews { }

/// A protocol representing a subview so that we can inject mocks in unit tests.
protocol FlowLayoutSubview {
    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize
    func place(at position: CGPoint, anchor: UnitPoint, proposal: ProposedViewSize)
}

extension LayoutSubview: FlowLayoutSubview { }
