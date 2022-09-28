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

public struct WeakDictionary<Key: Hashable, Value: AnyObject> {
    private var storage: [Key: WeakDictionaryReference<Value>]

    public init() {
        self.init(storage: [Key: WeakDictionaryReference<Value>]())
    }

    public init(dictionary: [Key: Value]) {
        var newStorage = [Key: WeakDictionaryReference<Value>]()
        dictionary.forEach { key, value in newStorage[key] = WeakDictionaryReference<Value>(value: value) }
        self.init(storage: newStorage)
    }

    private init(storage: [Key: WeakDictionaryReference<Value>]) {
        self.storage = storage
    }

    public mutating func reap() {
        storage = weakDictionary().storage
    }

    public func weakDictionary() -> WeakDictionary<Key, Value> {
        self[startIndex..<endIndex]
    }

    public func dictionary() -> [Key: Value] {
        var newStorage = [Key: Value]()

        storage.forEach { key, value in
            if let retainedValue = value.value {
                newStorage[key] = retainedValue
            }
        }

        return newStorage
    }
}

extension WeakDictionary: Collection {
    public typealias Index = DictionaryIndex<Key, WeakDictionaryReference<Value>>

    public var startIndex: Index {
        storage.startIndex
    }

    public var endIndex: Index {
        storage.endIndex
    }

    public func index(after index: Index) -> Index {
        storage.index(after: index)
    }

    public subscript(position: Index) -> (Key, WeakDictionaryReference<Value>) {
        return storage[position]
    }

    public subscript(key: Key) -> Value? {
        get {
            guard let valueRef = storage[key] else {
                return nil
            }

            return valueRef.value
        }

        set {
            guard let value = newValue else {
                storage[key] = nil
                return
            }

            storage[key] = WeakDictionaryReference<Value>(value: value)
        }
    }

    public subscript(bounds: Range<Index>) -> WeakDictionary<Key, Value> {
        let subStorage = storage[bounds.lowerBound..<bounds.upperBound]
        var newStorage = [Key: WeakDictionaryReference<Value>]()

        subStorage.filter { _, value in value.value != nil }
            .forEach { key, value in newStorage[key] = value }

        return WeakDictionary<Key, Value>(storage: newStorage)
    }
}

public extension Dictionary where Value: AnyObject {
    func weakDictionary() -> WeakDictionary<Key, Value> {
        WeakDictionary<Key, Value>(dictionary: self)
    }
}
