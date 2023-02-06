//
//  RootModelProperty.swift
//  Teibolto Classic
//
//  Created by Óscar Morales Vivó on 12/11/22.
//

import Combine
import Foundation

// MARK: - ModelProperty Implementation

public extension ModelProperty {
    /**
     Builds and returns a model property for standalone model data.

     This setup of a `ModelProperty` just stores a value of a given type and updates it as requested. It can be
     used as the root model property for a controller hierarchy or in other cases where a straight stored property
     works well enough.

     Keep in mind that while `ModelProperty` is a value type, it will act as a reference type if you copy one of these
     around as the stored value will be shared among all copies of the model property.
     */
    func rootModelProperty(initialValue: Model, validator: @escaping Validator<Model> = emptyValidator()) -> ModelProperty {
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
