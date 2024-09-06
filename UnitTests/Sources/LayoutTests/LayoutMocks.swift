//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

@testable import ElementX
import Foundation
import SwiftUI

/// A mock of the SwiftUI `LayoutSubviews` struct
struct LayoutSubviewsMock: Equatable, RandomAccessCollection {
    var subviews: [LayoutSubviewMock]
    
    /// A type that contains a subsequence of proxy values.
    typealias SubSequence = LayoutSubviewsMock
    
    /// A type that contains a proxy value.
    typealias Element = LayoutSubviewMock
    
    /// A type that you can use to index proxy values.
    typealias Index = Int
    
    /// The index of the first subview.
    var startIndex: Int {
        subviews.startIndex
    }
    
    /// An index that's one higher than the last subview.
    var endIndex: Int {
        subviews.endIndex
    }
    
    /// Gets the subview proxy at a specified index.
    subscript(index: Int) -> LayoutSubviewsMock.Element {
        subviews[index]
    }
    
    /// Gets the subview proxies in the specified range.
    subscript(bounds: Range<Int>) -> LayoutSubviewsMock {
        LayoutSubviewsMock(subviews: Array(subviews[bounds]))
    }
}

/// A mock of the SwiftUI `LayoutSubview` struct
struct LayoutSubviewMock: FlowLayoutSubview, Equatable {
    var size: CGSize
    var layoutValues = [String: Any]()
    var placedPositionCallback: (CGRect) -> Void
    
    subscript<K>(key: K.Type) -> K.Value where K: LayoutValueKey {
        guard let value = layoutValues[String(describing: key.self)] as? K.Value else {
            fatalError("There is no value for the provided layout key.")
        }
        return value
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        size
    }
    
    func place(at position: CGPoint, anchor: UnitPoint, proposal: ProposedViewSize) {
        let rect = CGRect(origin: position, size: CGSize(width: proposal.width ?? 0, height: proposal.height ?? 0))
        placedPositionCallback(rect)
    }
    
    static func == (lhs: LayoutSubviewMock, rhs: LayoutSubviewMock) -> Bool {
        lhs.size == rhs.size
    }
}

extension LayoutSubviewsMock: FlowLayoutSubviews { }
