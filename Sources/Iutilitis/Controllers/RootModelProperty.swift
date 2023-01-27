//
//  RootModelProperty.swift
//  Teibolto Classic
//
//  Created by Óscar Morales Vivó on 12/11/22.
//

import Combine
import Foundation

/**
 A model property for standalone model data.

 This implementation of `ModelProperty` just stores a value of a given type and updates it as requested. It can be
 used as the root model property for a controller hierarchy.

 As the base storage for a model, it needs to be a reference type or its stored data will be duplicated around as
 other model properties inherit from it.
 */
public final class RootModelProperty<T: Equatable> {
    public init(initialValue: Model) {
        self.value = initialValue
    }

    private let subject = PassthroughSubject<Model, Never>()

    /**
     The model property's `value` property is directly settable for root model properties. For simple setups where there
     is no need to deal with validation concerns it allows for simply updating the data what controllers and subscribers
     manage.
     */
    public var value: Model {
        didSet {
            // Gate against equality updates.
            guard value != oldValue else {
                return
            }

            subject.send(value)
        }
    }
}

// MARK: - ModelProperty Implementation

extension RootModelProperty: ModelProperty {
    public typealias Model = T

    public var updatePublisher: UpdatePublisher {
        // Gotta add the error to the publisher despite `RootModelProperty` never throwing them.
        subject.eraseToAnyPublisher()
    }

    public func updateValue(to newValue: Model) {
        // Just a straight value update. The property itself does equality gating.
        value = newValue
    }
}
