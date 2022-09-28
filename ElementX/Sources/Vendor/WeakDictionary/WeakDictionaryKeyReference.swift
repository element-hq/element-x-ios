// MIT License
//
// Copyright (c) 2016 Nicholas Cross
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

public struct WeakDictionaryKey<Key: AnyObject & Hashable, Value: AnyObject>: Hashable {
    private weak var baseKey: Key?
    private let hash: Int
    private var retainedValue: Value?
    private let nilKeyHash = UUID().hashValue

    public init(key: Key, value: Value? = nil) {
        baseKey = key
        retainedValue = value
        hash = key.hashValue
    }

    public static func == (lhs: WeakDictionaryKey, rhs: WeakDictionaryKey) -> Bool {
        (lhs.baseKey != nil && rhs.baseKey != nil && lhs.baseKey == rhs.baseKey)
            || lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        if baseKey == nil {
            hasher.combine(nilKeyHash)
        } else {
            hasher.combine(baseKey)
        }
    }

    public var key: Key? {
        baseKey
    }
}
