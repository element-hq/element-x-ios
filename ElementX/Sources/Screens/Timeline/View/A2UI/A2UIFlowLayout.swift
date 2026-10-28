//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Lays out the children of an A2UI `Row`, wrapping onto new lines when they don't fit.
///
/// A message bubble is narrow, so a Row of several buttons rarely fits on one line. Stacks never wrap,
/// they squeeze every child instead, which breaks button labels one letter per line. This layout gives
/// each child its natural width and starts a new line when the next child doesn't fit. `justify`
/// distributes each line's spare width and `align` positions the children within their line. Children
/// with a `weight` share a line's spare width instead of wrapping, so a weighted Text still fills the
/// gap between an icon and a button.
nonisolated struct A2UIFlowLayout: Layout {
    let justify: A2UIContainer.Justify
    let align: A2UIContainer.Align
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: some FlowLayoutSubviews, cache: inout ()) -> CGSize {
        let lines = makeLines(availableWidth: proposal.width ?? .infinity, subviews: Array(subviews))
        let height = lines.map(\.height).reduce(0, +) + CGFloat(max(lines.count - 1, 0)) * lineSpacing
        
        // Fill the proposed width whenever spare width matters, otherwise hug the content so a short row doesn't widen the bubble.
        if let width = proposal.width, width.isFinite, fillsAvailableWidth(lines) {
            return CGSize(width: width, height: height)
        }
        return CGSize(width: lines.map(\.contentWidth).max() ?? 0, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: some FlowLayoutSubviews, cache: inout ()) {
        let lines = makeLines(availableWidth: bounds.width, subviews: Array(subviews))
        
        var lineY = bounds.minY
        for line in lines {
            let (leadingInset, gap) = distribution(ofSpareWidth: max(bounds.width - line.contentWidth, 0), itemCount: line.items.count)
            var x = bounds.minX + leadingInset
            for item in line.items {
                let y = lineY + verticalOffset(forItemHeight: item.size.height, lineHeight: line.height)
                let height = align == .stretch ? line.height : item.size.height
                item.subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(width: item.size.width, height: height))
                x += item.size.width + gap
            }
            lineY += line.height + lineSpacing
        }
    }
    
    // MARK: - Private
    
    private struct Item {
        let subview: FlowLayoutSubview
        var size: CGSize
        let weight: Double
    }
    
    private struct Line {
        var items = [Item]()
        /// The width of the items plus the spacing between them.
        var contentWidth: CGFloat = 0
        
        var height: CGFloat {
            items.map(\.size.height).max() ?? 0
        }
        
        mutating func append(_ item: Item, spacing: CGFloat) {
            contentWidth += (items.isEmpty ? 0 : spacing) + item.size.width
            items.append(item)
        }
    }
    
    private func makeLines(availableWidth: CGFloat, subviews: [FlowLayoutSubview]) -> [Line] {
        var lines = [Line]()
        var line = Line()
        
        for subview in subviews {
            let weight = weight(of: subview)
            let item = Item(subview: subview, size: naturalSize(of: subview, weight: weight, availableWidth: availableWidth), weight: weight)
            if !line.items.isEmpty, line.contentWidth + spacing + item.size.width > availableWidth {
                lines.append(line)
                line = Line()
            }
            line.append(item, spacing: spacing)
        }
        if !line.items.isEmpty {
            lines.append(line)
        }
        
        if availableWidth.isFinite {
            for index in lines.indices {
                distributeSpareWidth(in: &lines[index], availableWidth: availableWidth)
            }
        }
        return lines
    }
    
    /// A weighted child is only as wide as it has to be until the line's spare width is shared out.
    /// A child wider than the line gets the whole line, so long text wraps instead of overflowing.
    private func naturalSize(of subview: FlowLayoutSubview, weight: Double, availableWidth: CGFloat) -> CGSize {
        let proposal: ProposedViewSize = weight > 0 && availableWidth.isFinite ? .init(width: 0, height: nil) : .unspecified
        let size = subview.sizeThatFits(proposal)
        if size.width > availableWidth {
            return subview.sizeThatFits(ProposedViewSize(width: availableWidth, height: nil))
        }
        return size
    }
    
    private func distributeSpareWidth(in line: inout Line, availableWidth: CGFloat) {
        let totalWeight = line.items.map(\.weight).reduce(0, +)
        guard totalWeight > 0 else { return }
        
        let spareWidth = max(availableWidth - line.contentWidth, 0)
        for index in line.items.indices where line.items[index].weight > 0 {
            let item = line.items[index]
            let width = item.size.width + spareWidth * item.weight / totalWeight
            let height = item.subview.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
            line.items[index].size = CGSize(width: width, height: height)
        }
        line.contentWidth = line.items.map(\.size.width).reduce(0, +) + CGFloat(line.items.count - 1) * spacing
    }
    
    private func weight(of subview: FlowLayoutSubview) -> Double {
        let weight = subview[A2UIWeightLayoutKey.self]
        return weight > 0 ? weight : (justify == .stretch ? 1 : 0)
    }
    
    private func fillsAvailableWidth(_ lines: [Line]) -> Bool {
        justify != .start || lines.contains { $0.items.contains { $0.weight > 0 } }
    }
    
    /// Where the first item of a line starts and the gap between its items, given the line's spare width.
    private func distribution(ofSpareWidth spareWidth: CGFloat, itemCount: Int) -> (leadingInset: CGFloat, gap: CGFloat) {
        let count = CGFloat(itemCount)
        return switch justify {
        case .start, .stretch: (0, spacing)
        case .center: (spareWidth / 2, spacing)
        case .end: (spareWidth, spacing)
        case .spaceBetween: itemCount > 1 ? (0, spacing + spareWidth / (count - 1)) : (0, spacing)
        case .spaceAround: (spareWidth / (count * 2), spacing + spareWidth / count)
        case .spaceEvenly: (spareWidth / (count + 1), spacing + spareWidth / (count + 1))
        }
    }
    
    private func verticalOffset(forItemHeight itemHeight: CGFloat, lineHeight: CGFloat) -> CGFloat {
        switch align {
        case .start, .stretch: 0
        case .center: (lineHeight - itemHeight) / 2
        case .end: lineHeight - itemHeight
        }
    }
}

/// The `weight` of a Row child. `0` for children without a weight, which keep their natural width.
nonisolated struct A2UIWeightLayoutKey: LayoutValueKey {
    static let defaultValue: Double = 0
}

extension View {
    func a2uiWeight(_ weight: Double?) -> some View {
        layoutValue(key: A2UIWeightLayoutKey.self, value: weight ?? 0)
    }
}
