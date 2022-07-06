//
//  WeakDictionary.swift
//  WeakDictionary
//
//  Created by Nicholas Cross on 19/10/2016.
//  Copyright © 2016 Nicholas Cross. All rights reserved.
//

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
