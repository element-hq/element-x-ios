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
    
    /// Gets the subview proxies with the specified indicies.
    subscript<S>(indices: S) -> LayoutSubviewsMock where S: Sequence, S.Element == Int {
        LayoutSubviewsMock(subviews: Array(indices.map { subviews[$0] }))
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
