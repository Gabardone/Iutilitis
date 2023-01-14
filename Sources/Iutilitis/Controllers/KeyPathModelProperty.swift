//
//  KeyPathModelProperty.swift
//  Teibolto Classic
//
//  Created by Óscar Morales Vivó on 12/11/22.
//

import Combine
import Foundation

/**
 A model property that gets, sets and publishes the updates of one property of a larger, parent model property.
 */
struct KeyPathModelProperty<Root: Equatable, Value: Equatable> {
    /**
     We need to store the parent as to be able to access its full API.
     */
    var parent: any ModelProperty<Root>

    /**
     The key path pointing to the property we're extracting from and updating on the parent.
     */
    let keyPath: WritableKeyPath<Root, Value>
}

extension KeyPathModelProperty: ModelProperty {
    typealias Model = Value

    var value: Value {
        get throws {
            try parent.value[keyPath: keyPath]
        }
    }

    var updatePublisher: UpdatePublisher {
        parent.updatePublisher
            .map(keyPath)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    mutating func updateValue(to newValue: Value) throws {
        var parentValue = try parent.value
        parentValue[keyPath: keyPath] = newValue
        try parent.updateValue(to: parentValue)
    }
}
