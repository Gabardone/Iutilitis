//
//  File.swift
//
//
//  Created by Óscar Morales Vivó on 2/1/23.
//

import Foundation

extension ModelProperty {
    /**
     Builds a model property that maps the calling one into a different one.

     This is the general approach taken to generate child model properties with the most common ones also offered by the
     module, but it can also be used manually to generate other model properties when you have a clear way to map
     the calling model into a different type and any changes on the latter back.
     - Parameter map: A block that maps values of the original type into the values of the generated one. It is used
     both for the getter and the update publisher.
     - Parameter updater: A block that generates a new value of the caller's model based on its current value and a new
     value for the mapped type. It needs not guard against equality.
     - Parameter validator: A validator block. While the validator only takes in the child's mapped value, at the point
     of creation it should be simple enough to capture the parent if needed for a more holistic validation. This
     shouldn't cause reference cycles: The children capture the parent by design but the opposite should never happen.
     */
    func mappingModelProperty<Value>(
        map: @escaping (Model) -> Value,
        updater: @escaping (Model, Value) -> Model,
        validator: @escaping Validator<Value> = emptyValidator()
    ) -> ModelProperty<Value> {
        ModelProperty<Value>(
            updatePublisher: updatePublisher.map(map).removeDuplicates().eraseToAnyPublisher(),
            getter: {
                map(value)
            },
            setter: { newValue in
                guard map(value) != newValue else {
                    return
                }

                updateValue(updater(value, newValue))
            },
            validator: validator
        )
    }
}
