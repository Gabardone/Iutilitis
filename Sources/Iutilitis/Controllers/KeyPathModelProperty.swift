//
//  KeyPathModelProperty.swift
//  Teibolto Classic
//
//  Created by Óscar Morales Vivó on 12/11/22.
//

import Combine
import Foundation

extension ModelProperty {
    /**
     Builds a child model property that manages the property of the caller pointed at by the given `keyPath` and can
     validate updates.
     - Parameter keyPath: The keyPath for the property that is the value of the child model property.
     - Parameter validator: The validator that checks whether a new value of the property would be valid. If any
     parental context is needed for the validation it can be brought in the block without risk of a reference
     cycles.
     */
    func childModelProperty<Value>(
        keyPath: WritableKeyPath<Model, Value>,
        validator: @escaping Validator<Value> = emptyValidator()
    ) -> ModelProperty<Value> {
        mappingModelProperty(
            map: { model in
                model[keyPath: keyPath]
            },
            updater: { model, newValue in
                var updatedModel = model
                updatedModel[keyPath: keyPath] = newValue
                return updatedModel
            },
            validator: validator
        )
    }
}
