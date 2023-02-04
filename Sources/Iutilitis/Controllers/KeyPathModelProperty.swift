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
     The adapter block used to validate keyPath property updates on a keyPath child model property.
     */
    public typealias KeyPathPropertyValidator<Value> = (Model, Value) throws -> Void

    /**
     Builds a child model property that manages the property of the caller pointed at by the given `keyPath` and can
     validate updates.
     - Parameter keyPath: The keyPath for the property that is the value of the child model property.
     - Parameter validator: A `KeyPathPropertyValidator` that checks whether a new value of hte property would be
     valid within the context of the caller's current value.
     */
    func childModelProperty<Value>(
        keyPath: WritableKeyPath<Model, Value>,
        validator: @escaping KeyPathPropertyValidator<Value>
    ) -> ModelProperty<Value> {
        return mappingModelProperty(
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

    /**
     Builds a child model property that manages the property of the caller pointed at by the given `keyPath`.
     - Parameter keyPath: The keyPath for the property that is the value of the child model property.
     - Parameter validator: A `KeyPathPropertyValidator` that checks whether a new value of hte property would be
     valid within the context of the caller's current value.
     */
    func childModelProperty<Value>(
        keyPath: WritableKeyPath<Model, Value>
    ) -> ModelProperty<Value> {
        return mappingModelProperty(
            map: { model in
                model[keyPath: keyPath]
            },
            updater: { model, newValue in
                var updatedModel = model
                updatedModel[keyPath: keyPath] = newValue
                return updatedModel
            },
            validator: emptyKeyPathValidator()
        )
    }

    /**
     Builds a validator for a keyPath child model property that lets everyting through.

     Use with care.
     */
    func emptyKeyPathValidator<Value>() -> KeyPathPropertyValidator<Value> {
        { _, _ in }
    }

    /**
     Builds a validator for a keyPath child model property that just validates the new value.

     The validator can be used when any valid value of the type will be a valid value for the property in the
     encompassing model. If that is not the case use a custom validator or, if `Model` is validatable,
     `updatedKeyPathValidator` instead.
     - Returns: A validator that just checks for the new value being valid.
     */
    func newKeyPathValueValidator<Value: Validatable>() -> KeyPathPropertyValidator<Value> {
        { _, newValue in
            try newValue.validate()
        }
    }
}

extension ModelProperty where Model: Validatable {
    /**
     A default validator for keypath child model properties that builds an updated version of the model and validates
     it.

     This default validator builds a new model value with the updated property that the keypath points at and validates
     that.
     - Warning: Do _not_ use for reference model types, as it will modify the model whether validation succeeds or not.
     - Parameter keyPath: The keyPath pointing to the property that will be updated.
     - Returns: A validator that builds a new value of the model with the new value of the property and validates that.
     */
    static func updatedKeyPathValidator<Value>(
        keyPath: WritableKeyPath<Model, Value>
    ) -> KeyPathPropertyValidator<Value> {
        { model, newValue in
            var updatedModel = model
            updatedModel[keyPath: keyPath] = newValue
            try updatedModel.validate()
        }
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
     - Parameter validator: A validator that checks whether an update to `model[keyPath: keyPath]` would be valid. You
     can use one of the prebuilt ones.
     - Parameter persistence: The persistence to assing to the child controller. It's up to the surrounding logic to
     procure one of the right type.
     - Returns: a controller that manages the value at `keyPath` and will both update `self` if it gets edited and
     rebroadcast updates to that value happening elsewhere.
     */
    func managedChildController<Value: Equatable, T: ManagedObject, P>(
        forPropertyAtKeyPath keyPath: WritableKeyPath<Model, Value>,
        validator: @escaping ModelProperty<Model>.KeyPathPropertyValidator<Value>,
        persistence: P
    ) -> T where T: Controller<ID, Value, P>, T.ID == ID {
        T.manager.controller(forID: id) {
            T(
                for: id,
                with: modelProperty.childModelProperty(keyPath: keyPath, validator: validator),
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
     - Parameter validator: A validator that checks whether an update to `model[keyPath: keyPath]` would be valid. You
     can use one of the prebuilt ones.
     - Returns: a controller that manages the value at `keyPath` and will both update `self` if it gets edited and
     rebroadcast updates to that value happening elsewhere.
     */
    func managedChildController<Value: Equatable, T: ManagedObject>(
        forPropertyAtKeyPath keyPath: WritableKeyPath<Model, Value>,
        validator: @escaping ModelProperty<Model>.KeyPathPropertyValidator<Value>
    ) -> T where T: Controller<ID, Value, Void>, T.ID == ID {
        T.manager.controller(forID: id) {
            T(
                for: id,
                with: modelProperty.childModelProperty(keyPath: keyPath, validator: validator),
                persistence: ()
            )
        }
    }
}
