//
//  KeyValueModelProperty.swift
//  Teibolto Classic
//
//  Created by Óscar Morales Vivó on 12/27/22.
//

import Combine
import Foundation

/**
 For some reason the Swift standard library does not declare a protocol for types that map values to keys. We correct
 that here so different types can be used with `KeyValueModelProperty`.
 - Note: If you're using the `swift-collections` package, the `OrderedDictionary` type can also fulfill the protocol
 without any modification. It is not declared here as to avoid bringing in the dependency.
 */
public protocol KeyValueCollection {
    associatedtype Key: Hashable
    associatedtype Value

    subscript(_: Key) -> Value? { get set }
}

/**
 `Dictionary` implements `KeyValueCollection` by default, but it needs declarin'
 */
extension Dictionary: KeyValueCollection {}

extension ModelProperty where Model: KeyValueCollection, Model.Value: Equatable {
    /**
     The adapter block used to validate keyPath property updates on a keyPath child model property.
     */
    public typealias KeyValuePropertyValidator<Value> = (Model, Value) throws -> Void

    /**
     Builds a child model property that manages the property of the caller pointed at by the given `keyPath` and can
     validate updates.
     - Parameter keyPath: The keyPath for the property that is the value of the child model property.
     - Parameter validator: A `KeyPathPropertyValidator` that checks whether a new value of hte property would be
     valid within the context of the caller's current value.
     */
    func childModelProperty(
        key: Model.Key,
        initialValue: Model.Value,
        validator: @escaping Validator<Model.Value> = emptyValidator()
    ) -> ModelProperty<Model.Value> {
        var lastValue = initialValue
        return mappingModelProperty(
            map: { model in
                // Update last value if needed.
                if let parentValue = model[key] {
                    lastValue = parentValue
                }
                return lastValue
            },
            updater: { model, newValue in
                lastValue = newValue
                var updatedModel = model
                updatedModel[key] = newValue
                return updatedModel
            },
            validator: validator
        )
    }
}
