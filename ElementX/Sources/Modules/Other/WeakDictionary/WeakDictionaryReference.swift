//
//  WeakDictionaryReference.swift
//  WeakDictionary-iOS
//
//  Created by Nicholas Cross on 2/1/19.
//  Copyright © 2019 Nicholas Cross. All rights reserved.
//

import Foundation

public struct WeakDictionaryReference<Value: AnyObject> {
    private weak var referencedValue: Value?

    init(value: Value) {
        referencedValue = value
    }

    public var value: Value? {
        return referencedValue
    }
}
