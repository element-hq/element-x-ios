//
//  WeakDictionaryKeyReference.swift
//  WeakDictionary-iOS
//
//  Created by Nicholas Cross on 2/1/19.
//  Copyright © 2019 Nicholas Cross. All rights reserved.
//

import Foundation

public struct WeakDictionaryKey<Key: AnyObject & Hashable, Value: AnyObject> : Hashable {

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
        return (lhs.baseKey != nil && rhs.baseKey != nil && lhs.baseKey == rhs.baseKey)
            || lhs.hashValue == rhs.hashValue
    }

    public var hashValue: Int {
        return baseKey != nil ? hash : nilKeyHash
    }

    public var key: Key? {
        return baseKey
    }
}
