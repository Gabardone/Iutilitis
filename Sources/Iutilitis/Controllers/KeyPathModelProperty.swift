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
        parent.value[keyPath: keyPath]
    }

    var updatePublisher: UpdatePublisher {
        parent.updatePublisher
            .map(keyPath)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    mutating func updateValue(to newValue: Value) throws {
        var parentValue = parent.value
        parentValue[keyPath: keyPath] = newValue
        try parent.updateValue(to: parentValue)
    }
}

// MARK: - Controller Child management

public extension Controller {
    /**
     Returns a managed child controller to whose model is the value at the given model's keypath.

     This method works for controller types managed by a `ControllerManager` so you'll get the same one if it's already
     been created and is being held by someone else.

     The ID of the child view controller is assumed to be the same as the caller since the type should be the same.
     - Parameter keyPath: A keypath pointing to the property we want a child controller for.
     - Parameter persistence: The persistence to assing to the child controller. It's up to the surrounding logic to
     procure one of the right type.
     - Returns: a controller that manages the value at `keyPath` and will both update `self` if it gets edited and
     rebroadcast updates to that value happening elsewhere.
     */
    func managedChildController<Value: Equatable, T: ManagedObject, P>(
        forPropertyAtKeyPath keyPath: WritableKeyPath<Model, Value>,
        persistence: P
    ) -> T where T: Controller<ID, Value, P>, T.ID == ID {
        T.manager.controller(forID: id) {
            T(
                for: id,
                with: KeyPathModelProperty(parent: modelProperty, keyPath: keyPath),
                persistence: persistence
            )
        }
    }

    /**
     Returns a managed child controller to whose model is the value at the given model's keypath and which does no
     persistence.

     Most of the time child controllers that do no persistence will be the children of parent controllers that don't
     do persistence, but exceptions may occur. Just make sure that your overall controller design works for your
     purposes.

     This method works for controller types managed by a `ControllerManager` so you'll get the same one if it's already
     been created and is being held by someone else.

     The ID of the child view controller is assumed to be the same as the caller since the type should be the same.
     - Parameter keyPath: A keypath pointing to the property we want a child controller for.
     - Returns: a controller that manages the value at `keyPath` and will both update `self` if it gets edited and
     rebroadcast updates to that value happening elsewhere.
     */
    func managedChildController<Value: Equatable, T: ManagedObject>(
        forPropertyAtKeyPath keyPath: WritableKeyPath<Model, Value>
    ) -> T where T: Controller<ID, Value, Void>, T.ID == ID {
        T.manager.controller(forID: id) {
            T(
                for: id,
                with: KeyPathModelProperty(parent: modelProperty, keyPath: keyPath),
                persistence: ()
            )
        }
    }
}
