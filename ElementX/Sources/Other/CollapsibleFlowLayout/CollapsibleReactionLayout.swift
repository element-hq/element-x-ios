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

/// A flow layout that will show a collapse/expand button when the layout wraps over a defined number of lines.
/// With n subviews passed to the layout, n-2 first views represent the main views to be laid out.
/// The n-1th subview is the collapse/expand button which is only shown when the layout overflows `linesBeforeCollapsible` number of lines.
/// When the button is shown it is tagged on the end of the collapsed or expanded layout.
/// The nth subview is a supplementary subview which is  shown when there are greater than 0 subviews.
struct CollapsibleReactionLayout: Layout {
    /// The horizontal spacing between items
    let itemSpacing: CGFloat
    /// The vertical spacing between lines
    let lineSpacing: CGFloat
    /// The number of lines before the collapse/expand button is shown
    let linesBeforeCollapsible: Int?
    /// Whether the layout should display in expanded or collapsed state
    var collapsed: Bool
    
    init(itemSpacing: CGFloat = 0,
         lineSpacing: CGFloat = 0,
         collapsed: Bool = true,
         linesBeforeCollapsible: Int? = nil) {
        self.itemSpacing = itemSpacing
        self.lineSpacing = lineSpacing
        self.collapsed = collapsed
        self.linesBeforeCollapsible = linesBeforeCollapsible
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: some FlowLayoutSubviews, cache: inout ()) -> CGSize {
        let collapseButton = subviews[subviews.count - 2]
        let addMoreButton = subviews[subviews.count - 1]
        let reactions = subviews.prefix(subviews.count - 2)
        // Calculate the layout of the lines with the reactions button and add more button
        let reactionsAndAddMore = calculateLines(proposal: proposal, subviews: Array(reactions + [addMoreButton]))
        // If we have extended beyond the defined number of lines we are showing the expand/collapse ui
        if let linesBeforeCollapsible, reactionsAndAddMore.count > linesBeforeCollapsible {
            if collapsed {
                // Truncate to `linesBeforeCollapsible` number of lines and replace the item at the end of the last line with the button
                let collapsedLines = Array(reactionsAndAddMore.prefix(linesBeforeCollapsible))
                let (collapsedLinesWithButtons, _) = replaceTailingItemsWithButtons(lineWidth: proposal.width ?? 0, lines: collapsedLines, collapseButton: collapseButton, addMoreButton: addMoreButton)
                let size = sizeThatFits(proposal: proposal, lines: collapsedLinesWithButtons)
                return size
            } else {
                // Show all subviews with the button at the end
                var linesWithButtons = calculateLines(proposal: proposal, subviews: Array(subviews))
                ensureCollapseAndAddMoreButtonsOnTheSameLine(&linesWithButtons)
                let size = sizeThatFits(proposal: proposal, lines: linesWithButtons)
                return size
            }
        } else {
            // Otherwise we are just calculating the size of all items without the button
            return sizeThatFits(proposal: proposal, lines: reactionsAndAddMore)
        }
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: some FlowLayoutSubviews, cache: inout ()) {
        let collapseButton = subviews[subviews.count - 2]
        let addMoreButton = subviews[subviews.count - 1]
        let reactions = subviews.prefix(subviews.count - 2)
        // Calculate the layout of the lines with the reactions button and add more button
        let reactionsAndAddMore = calculateLines(proposal: ProposedViewSize(bounds.size), subviews: Array(reactions + [addMoreButton]))
        // If we have extended beyond the defined number of lines we are showing the expand/collapse ui
        if let linesBeforeCollapsible, reactionsAndAddMore.count > linesBeforeCollapsible {
            if collapsed {
                // Truncate to `linesBeforeCollapsible` number of lines and replace the item at the end of the last line with the button
                let collapsedLines = Array(reactionsAndAddMore.prefix(linesBeforeCollapsible))
                let (collapsedLinesWithButtons, subviewsToHide) = replaceTailingItemsWithButtons(lineWidth: bounds.width, lines: collapsedLines, collapseButton: collapseButton, addMoreButton: addMoreButton)
                
                var remainingSubviews = subviewsToHide + Array(reactionsAndAddMore.suffix(reactionsAndAddMore.count - linesBeforeCollapsible)).joined()
                // remove the add button which was in initial lines calculation
                remainingSubviews.removeLast()
                placeSubviews(in: bounds, lines: collapsedLinesWithButtons)
                // "Remove" (place with a proposed zero frame) any additional subviews
                remainingSubviews.forEach { subview in
                    subview.place(at: CGPoint(x: bounds.minX - 1000, y: bounds.minY - 1000), anchor: .leading, proposal: .zero)
                }
                
            } else {
                // Show all subviews with the buttons at the end
                var linesWithButtons = calculateLines(proposal: ProposedViewSize(bounds.size), subviews: Array(subviews))
                ensureCollapseAndAddMoreButtonsOnTheSameLine(&linesWithButtons)
                placeSubviews(in: bounds, lines: linesWithButtons)
            }
        } else {
            // Otherwise we are just placing the reactions and add button
            placeSubviews(in: bounds, lines: reactionsAndAddMore)
            // "Remove"(place with a proposed zero frame) the collapse button
            collapseButton.place(at: CGPoint(x: bounds.minX - 1000, y: bounds.minY - 1000), anchor: .leading, proposal: .zero)
        }
    }
    
    /// Given a proposed size and a flat list of subviews, calculates and returns a structure representing
    /// how the subviews should wrap on to multiple lines given the size's width.
    /// - Parameters:
    ///   - proposal: The proposed size
    ///   - subviews: The subviews
    /// - Returns: A 2d array, the first dimension representing the lines, the second being the items per line.
    private func calculateLines(proposal: ProposedViewSize, subviews: [FlowLayoutSubview]) -> [[FlowLayoutSubview]] {
        var lines = [[FlowLayoutSubview]]()
        var currentLine = [FlowLayoutSubview]()
        
        var lineX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let hSpacing = currentLine.isEmpty ? 0 : itemSpacing
            // If the current view does not fine on this line bump to the next
            if lineX + size.width > proposal.width ?? 0 {
                lines.append(currentLine)
                currentLine = [LayoutSubview]()
                lineX = 0
            }
            lineX += hSpacing + size.width
            currentLine.append(subview)
        }
        // If there is more in the current line remember to append it on
        if currentLine.count > 0 {
            lines.append(currentLine)
        }
        return lines
    }
    
    /// Given a list of lines calculate the size needed to display them
    /// - Parameters:
    ///   - proposal: The proposed size
    ///   - lines: The list of lines
    /// - Returns: The size render the lines
    private func sizeThatFits(proposal: ProposedViewSize, lines: [[FlowLayoutSubview]]) -> CGSize {
        lines.enumerated().reduce(CGSize.zero) { partialResult, lineItem in
            let (lineIndex, line) = lineItem
            let lineSize = line.enumerated().reduce(CGSize.zero) { partialResult, subviewItem in
                let (subviewIndex, subview) = subviewItem
                let size = subview.sizeThatFits(.unspecified)
                let hSpacing = subviewIndex == 0 ? 0 : itemSpacing
                return CGSize(width: partialResult.width + size.width + hSpacing, height: max(partialResult.height, size.height))
            }
            let vSpacing = lineIndex == 0 ? 0 : lineSpacing
            return CGSize(width: max(partialResult.width, lineSize.width), height: partialResult.height + lineSize.height + vSpacing)
        }
    }
    
    /// Used to render the collapsed state, this takes the lines inputted and adds the button to the last line,
    /// removing only as many trailing subviews as needed to make space for it. It also returns the items removed.
    /// - Parameters:
    ///   - lineWidth: The width of the parent
    ///   - lines: The input list of lines
    ///   - button: The button to replace the trailing items
    /// - Returns: The new lines structure with button replaced and the subviews remove from the input to make space for the button
    private func replaceTailingItemsWithButtons(lineWidth: CGFloat, lines: [[FlowLayoutSubview]], collapseButton: FlowLayoutSubview, addMoreButton: FlowLayoutSubview) -> ([[FlowLayoutSubview]], [FlowLayoutSubview]) {
        var lines = lines
        let lastLine = lines[lines.count - 1]
        let collapseButtonSize = collapseButton.sizeThatFits(.unspecified)
        let addMoreButtonSize = addMoreButton.sizeThatFits(.unspecified)
        let buttonsWidth = collapseButtonSize.width + itemSpacing + addMoreButtonSize.width
        var lineX: CGFloat = 0
        for (i, subview) in lastLine.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            let hSpacing = i == 0 ? 0 : itemSpacing
            lineX += size.width + hSpacing
            if lineX > (lineWidth - (buttonsWidth + hSpacing)) {
                let lastLineWithButton = Array(lastLine.prefix(i)) + [collapseButton, addMoreButton]
                let subviewsToHide = Array(lastLine.suffix(lastLine.count - i))
                lines[lines.count - 1] = lastLineWithButton
                return (lines, subviewsToHide)
            }
        }
        let lastLineWithButton = Array(lastLine) + [collapseButton, addMoreButton]
        lines[lines.count - 1] = lastLineWithButton
        return (lines, [])
    }
    
    private func ensureCollapseAndAddMoreButtonsOnTheSameLine(_ lines: inout [[FlowLayoutSubview]]) {
        guard var lastLine = lines.last, lastLine.count == 1 else {
            return
        }
        var secondLastLine = lines[lines.count - 2]
        let collapseButton = secondLastLine.removeLast()
        lastLine.prepend(collapseButton)
        lines[lines.count - 2] = secondLastLine
        lines[lines.count - 1] = lastLine
    }
    
    /// Given a list of lines place them in the layout.
    /// - Parameters:
    ///   - bounds: The bounds of the parent
    ///   - lines: THe input line structure.
    private func placeSubviews(in bounds: CGRect, lines: [[FlowLayoutSubview]]) {
        var lineY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        
        let sizes = lines.map { line in
            line.map { subview in
                subview.sizeThatFits(.unspecified)
            }
        }
        
        let maxHeight = sizes.joined().reduce(0) { partialResult, size in
            max(partialResult, size.height)
        }
        
        for (i, line) in sizes.enumerated() {
            var lineX: CGFloat = bounds.minX
            let vSpacing = i == 0 ? 0 : lineSpacing
            for (j, size) in line.enumerated() {
                let subview = lines[i][j]
                let hSpacing = j == 0 ? 0 : itemSpacing
                let point = CGPoint(x: lineX + hSpacing, y: lineY + vSpacing + (maxHeight / 2))
                subview.place(at: point, anchor: .leading, proposal: ProposedViewSize(CGSize(width: size.width, height: maxHeight)))
                lineHeight = max(lineHeight, maxHeight)
                lineX += size.width + hSpacing
            }
            lineY += lineHeight + vSpacing
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
