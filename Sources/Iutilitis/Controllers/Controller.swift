//
//  Controller.swift
//  Teibolto Classic
//
//  Created by Óscar Morales Vivó on 12/11/22.
//

import Combine
import Foundation
import os

// Swift does not support static members on generic classes so we build a global controller logger object.
private let controllerLogger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Controller")

/**
 A generic controller class that manages a model.

 The model storage and update validation logic is abstract, hidden behind a protocol, which allows for flexibility
 building things like hierarchical controllers where you can for example build a controller for a part of a larger model
 (see `KeyPathModelProperty` for the most common child controller builder).

 An instance can be used to both feed SwiftUI views (therefore the compliance with `ObservableObject`) and UIKit ones
 through manual subscription to its model publisher.

 `Model` can be any type that conforms to equatable but value types are recommended. Special care must be taken when
 using reference types as there's nothing in the Swift language that prevents their contents from being modified outside
 the controller's scope.

 - Todo: Consider building a controller manager (hard to do right with Swift's limitations on generics. May need to
 make them injectable).
 */
class Controller<ID: Hashable, Model: Equatable>: Identifiable, ObservableObject {
    /**
     Designated initializer.

     The designated initializer for a controller takes an id, a model property and an initial value for the model and
     sets up the controller with them.

     The initial value is requested because a model property does not guarantee successful access to its `value`,
     otherwise this would need to be a `throw` initializer. If the model property is known to guarantee safe access to
     its `value` (i.e. a `RootModelProperty`) then it's easy enough to just extract its `value` for the `initialValue`
     parameter.
     - parameter id: The id for the controller. It is immutable once set.
     - parameter modelProperty: Model property that this controller will manage. Immutable once set.
     - parameter initialValue: A safe initial value for the controller.
     */
    required init<T: ModelProperty>(for id: ID, with modelProperty: T, initialValue: Model) where T.Model == Model {
        self.id = id
        self.model = initialValue
        self.modelProperty = modelProperty

        // Make sure updates on the abstract model property reflect on the stored property. If there's an error
        // upstream we just stop updating since `@Published` doesn't support errors.
        modelProperty.updatePublisher
            .catch { [weak self] error in
                controllerLogger.error("Controller \(String(describing: self)) received update error from model property \(String(describing: modelProperty)). Error: \(error.localizedDescription)")
                return Empty<Model, Never>()
            }
            .assign(to: &$model)
    }

    typealias ID = ID

    typealias Model = Model

    /// The controller's unique ID for the type.
    let id: ID

    /**
     The model value currently held by the controller.

     The setter is not publically accessible, it should only be updated from the outside indirectly through use of
     `apply(edit:)`. Per the behavior of its managed model property it should only update if the new value is different
     than the currently stored one, so there is no need to use `removeDuplicates` on the projected publisher.

     Vended as an `@Published` property wrapper so it can more easily be used to feed SwiftUI views.
     - Warning: `@Publisher` emits updates on `willSet`, so remember to use the given value but not check on the
     original property value when receiving updates to your subscription. That also means that often child controllers
     will receive updates before their parents have updated.
     */
    @Published
    private(set) var model: Model

    /**
     The model property that the controller is managing.
     */
    private var modelProperty: any ModelProperty<Model>
}

// MARK: - Editing

extension Controller {
    /**
     The edit block type for a controller.

     The block takes an initial value, applies any changes to it as desired, and returns the resulting value.

     If the edit cannot be applied to the given initial value, the block should throw and no changes should be made.
     */
    typealias Edit = (Model) throws -> Model

    /**
     Applies the given edit to the current model value and updates it with the result.

     The method will throw if either the edit or model update do so, which should happen only if the edit cannot be
     applied .
     - Precondition: `model.value.validate()` would not throw.
     - Postcondition: `model.value.validate()` would not throw.
     - Todo: Undo/Redo support.
     - Todo: Persistence support.
     */
    func apply(edit: Edit) throws {
        let newValue = try edit(modelProperty.value)
        try modelProperty.updateValue(to: newValue)
    }
}

// MARK: - Controller Child management

extension Controller {
    /**
     Returns a managed child controller to whose model is the value at the given model's keypath.

     This method works for controller types managed by a `ControllerManager` so you'll get the same one if it's already
     been created and is being held by someone else.

     The ID of the child view controller is assumed to be the same as the caller since the type should be the same.
     - Todo: Revisit child controller ID assumptions if there's a need to manage child controllers for several different
     keypaths pointing to different values of the same type.
     - Parameter keyPath: A keypath pointing to the property we want a child controller for.
     - Returns: a controller that manages the value at `keyPath` and will both update `self` if it gets edited and
     rebroadcast updates to that value happening elsewhere.
     */
    func managedChildController<Value: Equatable, T: ManagedObject>(
        forPropertyAtKeyPath keyPath: WritableKeyPath<Model, Value>
    ) -> T where T: Controller<ID, Value>, T.ID == ID {
        T.manager.controller(forID: id) {
            T(
                for: id,
                with: KeyPathModelProperty(parent: modelProperty, keyPath: keyPath),
                initialValue: model[keyPath: keyPath]
            )
        }
    }

    /**
     Returns a managed child controller whose model is a value within a key value container within the calling
     controller.

     The method will return an existing controller for the value if found within its manager, or will build —and set up
     within its type's manager— a new controller based on the currently held value.

     The method may throw a `KeyValueModelProperty.ValueNotFoundError` if its container key points to no value
     whatsoever.
     - Parameter containerKeyPath: A key path from the model to a key value container within. Use `\.self` if the model
     itself is the key value container.
     - Parameter containerKey: The key to access within the key value container pointed at by `containerKeyPath`.
     - Parameter valueKeyPath: The key path from the `container[containerKey]` to the actual value we want to control.
     If the container value itself is what we want just use `\.self`.
     - Returns: A controller whose model is the value at
     `model[keyPath: containerKeyPath][containerKey][keyPath: valueKeyPath]`.
     */
    func managedChildController<Container: KeyValueCollection, Value: Equatable, T: ManagedObject>(
        forValueWithinKeyValueContainerAtKeyPath containerKeyPath: WritableKeyPath<Model, Container>,
        containerKey key: Container.Key,
        valueKeyPath: WritableKeyPath<Container.Value, Value>
    ) throws -> T where T: Controller<Container.Key, Value>, T.ID == Container.Key {
        try T.manager.controller(forID: key) {
            guard let initialValue = model[keyPath: containerKeyPath][key]?[keyPath: valueKeyPath] else {
                // We can't safely create a controller without an initial value.
                throw KeyValueModelProperty<Model, Container, Value>.ValueNotFoundError(key: key)
            }

            return T(
                for: key,
                with: KeyValueModelProperty(
                    parent: modelProperty,
                    containerKeyPath: containerKeyPath,
                    key: key,
                    valueKeyPath: valueKeyPath
                ),
                initialValue: initialValue
            )
        }
    }

    /**
     Returns a managed child controller whose model is a value within a key value container within the calling
     controller, or creates it otherwise.

     The method will return an existing controller for the value if found within its manager, or will build —and set up
     within its type's manager— a new controller based on the currently held value and given initial value.

     Unlike the `initialValue`-less method, this will create a controller no matter what. The expectation is that its
     key will be added to the parent key value storage soon enough. For example this may happen for hierarchical
     controllers based on `@Published` key value storage properties as those emit to their subscribers _before_ their
     actual value update.
     - Parameter containerKeyPath: A key path from the model to a key value container within. Use `\.self` if the model
     itself is the key value container.
     - Parameter containerKey: The key to access within the key value container pointed at by `containerKeyPath`.
     - Parameter valueKeyPath: The key path from the `container[containerKey]` to the actual value we want to control.
     If the container value itself is what we want just use `\.self`.
     - Parameter initialValue: The initial value for the controller if one has to be created from scratch.
     - Returns: A controller whose model is the value at
     `model[keyPath: containerKeyPath][containerKey][keyPath: valueKeyPath]`.
     */
    func managedChildController<Container: KeyValueCollection, Value: Equatable, T: ManagedObject>(
        forValueWithinKeyValueContainerAtKeyPath containerKeyPath: WritableKeyPath<Model, Container>,
        containerKey key: Container.Key,
        valueKeyPath: WritableKeyPath<Container.Value, Value>,
        initialValue: Value
    ) -> T where T: Controller<Container.Key, Value>, T.ID == Container.Key {
        T.manager.controller(forID: key) {
            T(
                for: key,
                with: KeyValueModelProperty(
                    parent: modelProperty,
                    containerKeyPath: containerKeyPath,
                    key: key,
                    valueKeyPath: valueKeyPath
                ),
                initialValue: initialValue
            )
        }
    }
}
