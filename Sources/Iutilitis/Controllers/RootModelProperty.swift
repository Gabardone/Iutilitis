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
public class RootModelProperty<T: Equatable> {
    public init(initialValue: Model) {
        self.storage = initialValue
    }

    private let subject = PassthroughSubject<Model, Never>()

    private var storage: Model {
        didSet {
            // Storage assignment is gated by an equality check so we don't need to repeat it here.
            subject.send(value)
        }
    }
}

// MARK: - ModelProperty Implementation

extension RootModelProperty: ModelProperty {
    public typealias Model = T

    public var value: Model {
        storage
    }

    public var updatePublisher: UpdatePublisher {
        // Gotta add the error to the publisher despite `RootModelProperty` never throwing them.
        subject.setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    public func updateValue(to newValue: Model) {
        // Just straight running the block works for a root
        if storage != newValue {
            storage = newValue
        }
    }
}

public extension Controller {
    convenience init(for id: ID, with rootModelProperty: RootModelProperty<Model>) {
        self.init(for: id, with: rootModelProperty, initialValue: rootModelProperty.value)
    }
}
