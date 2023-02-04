//
//  RootModelProperty.swift
//  Teibolto Classic
//
//  Created by Óscar Morales Vivó on 12/11/22.
//

import Combine
import Foundation

// MARK: - ModelProperty Implementation

extension ModelProperty {
    /**
     Builds and returns a model property for standalone model data.

     This setup of a `ModelProperty` just stores a value of a given type and updates it as requested. It can be
     used as the root model property for a controller hierarchy or in other cases where a straight stored property
     works well enough.

     Keep in mind that while `ModelProperty` is a value type, it will act as a reference type if you copy one of these
     around as the stored value will be shared among all copies of the model property.
     */
    public func rootModelProperty(initialValue: Model, validator: @escaping Validator = { _ in }) -> ModelProperty {
        let passthroughSubject = PassthroughSubject<Model, Never>()
        var value = initialValue
        return ModelProperty(
            updatePublisher: passthroughSubject.eraseToAnyPublisher(),
            getter: {
                value
            },
            setter: { newValue in
                guard value != newValue else {
                    return
                }

                value = newValue
                passthroughSubject.send(newValue)
            },
            validator: validator
        )
    }
}

extension ModelProperty where Model: Validatable {
    /**
     Builds and returns a model property for standalone validatable model data.

     For validatable types we can default the validator of a root model property to just running the `validate` method
     for the new value. If something more sophisticate is needed you can always fall back to the regular factory method.
     */
    public func rootModelProperty(initialValue: Model) -> ModelProperty {
        return rootModelProperty(initialValue: initialValue) { newValue in
            try newValue.validate()
        }
    }
}
