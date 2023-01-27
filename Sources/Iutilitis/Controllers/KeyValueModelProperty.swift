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

/**
 A model property that gets, sets and publishes the updates of one property of a larger, parent model property
 contained in a key/value collection (i.e. a `Dictionary`).

 The model property has no say on what the parent does with its referred value so there's a chance that at some point
 it will not be there when accessed. If that happens, the model property will keep returning the last value set as its
 `value` but will fail any attempt at setting the value by throwing a `ValueNotFoundInParentError`. If the value
 reappears again (say by an undo operation) the controller will resume fully working again.

 Normally the above will only happen when a deletion happens so at that point the affected key value model property
 will be on its way out. More sophisticated behaviors dependant on the above are not recommended as a clear case of
 "trying to be too smart".

 Swift's support for keypath access to a type's data doesn't extend to digging into dictionaries and other key-value
 storage types, so this type is needed to bridge those gaps and deal with the possibility of a missing value for the
 given container key.

 Due to the need to maintain and update internal state (mostly `lastValue`) this cannot be a value type.
 */
class KeyValueModelProperty<Root: Equatable, Container: KeyValueCollection, Value: Equatable> {
    typealias Key = Container.Key

    /**
     We need to store the parent as to be able to access its full API.
     */
    var parent: any ModelProperty<Root>

    /**
     The key path pointing to the key-value container we're extracting from and updating on the parent.

     If the model itself is the key-value container, use `\.self` to initialize the model property.
     */
    let containerKeyPath: WritableKeyPath<Root, Container>

    /**
     The key used to access the value in the
     */
    let key: Key

    /**
     The key path digging in from the value extracted from the key-value container to the one we want to manage.

     If the value in the container itself is what we want to manage just use `\.self` to initialize
     */
    let valueKeyPath: WritableKeyPath<Container.Value, Value>

    /// We cache the publisher once (if) we build it so to avoid recreating it and making the copies do redundant work.
    private var cachedUpdatePublisher: AnyPublisher<Value, Never>?

    /// Keeps the last value updated in case the parent stops managing it.
    private var lastValue: Value

    init(
        parent: any ModelProperty<Root>,
        containerKeyPath: WritableKeyPath<Root, Container>,
        key: Key,
        valueKeyPath: WritableKeyPath<Container.Value, Value>,
        initialValue: Value
    ) {
        self.parent = parent
        self.containerKeyPath = containerKeyPath
        self.key = key
        self.valueKeyPath = valueKeyPath
        self.lastValue = initialValue
    }
}

extension KeyValueModelProperty: ModelProperty {
    typealias Model = Value

    struct ValueNotFoundInParentError: Error {
        var key: Key

        var localizedDescription: String {
            "Value of type \(type(of: Value.self)) not found for key \(key)"
        }
    }

    /**
     Access to the parent's value may throw if the parent is no longer holding on to it.
     */
    var value: Value {
        guard let result = parent.value[keyPath: containerKeyPath][key] else {
            // The value isn't being managed by the parent anymore.
            return lastValue
        }

        return result[keyPath: valueKeyPath]
    }

    /**
     `updatePublisher` may terminate with an error if an update of the parent model no longer contains the value
     this model publisher is managing.
     */
    var updatePublisher: UpdatePublisher {
        cachedUpdatePublisher ?? {
            // Build up the publisher.
            let updatePublisher = parent.updatePublisher
                .compactMap { [containerKeyPath, key, valueKeyPath] parentValue in
                    parentValue[keyPath: containerKeyPath][key]?[keyPath: valueKeyPath]
                }
                .removeDuplicates()
                .eraseToAnyPublisher()

            self.cachedUpdatePublisher = updatePublisher
            return updatePublisher
        }()
    }

    /**
     In addition to maybe throwing if the update of the parent cannot be completed, this method will throw if the
     managed value can no longer be found in the parent. We generally wouldn't want to set it otherwise.
     */
    func updateValue(to newValue: Value) throws {
        var parentValue = parent.value
        guard var updatingValue = parentValue[keyPath: containerKeyPath][key] else {
            // Make the update local.
            lastValue = newValue
            throw ValueNotFoundInParentError(key: key)
        }
        updatingValue[keyPath: valueKeyPath] = newValue
        parentValue[keyPath: containerKeyPath][key] = updatingValue
        try parent.updateValue(to: parentValue)
    }
}

// MARK: - Controller Child management

public extension Controller {
    /**
     Returns a managed child controller whose model is a value within a key value container within the calling
     controller.

     The method will return an existing controller for the value if found within its manager, or will build —and set up
     within its type's manager— a new controller based on the currently held value.

     The method may throw a `KeyValueModelProperty.ValueNotFoundError` if its container key points to no value
     whatsoever.
     - Warning: The controllers are managed by type and key, so make sure you only use managed controllers if the keys
     being used are unique within the context of the application. For example don't use an integer index as the key
     unless you're 100% sure that there is only one set of controllers of the type for the whole app.
     - Parameter containerKeyPath: A key path from the model to a key value container within. Use `\.self` if the model
     itself is the key value container.
     - Parameter containerKey: The key to access within the key value container pointed at by `containerKeyPath`.
     - Parameter valueKeyPath: The key path from the `container[containerKey]` to the actual value we want to control.
     If the container value itself is what we want just use `\.self`.
     - Parameter persistence: The persistence to assing to the child controller. It's up to the surrounding logic to
     procure one of the right type.
     - Returns: A controller whose model is the value at
     `model[keyPath: containerKeyPath][containerKey][keyPath: valueKeyPath]`.
     */
    internal func managedChildController<Container: KeyValueCollection, Value: Equatable, T: ManagedObject, P>(
        forValueWithinKeyValueContainerAtKeyPath containerKeyPath: WritableKeyPath<Model, Container>,
        containerKey key: Container.Key,
        valueKeyPath: WritableKeyPath<Container.Value, Value>,
        persistence: P
    ) throws -> T where T: Controller<Container.Key, Value, P>, T.ID == Container.Key {
        try T.manager.controller(forID: key) {
            guard let initialValue = model[keyPath: containerKeyPath][key]?[keyPath: valueKeyPath] else {
                // We can't safely create a controller without an initial value.
                throw KeyValueModelProperty<Model, Container, Value>.ValueNotFoundInParentError(key: key)
            }

            return T(
                for: key,
                with: KeyValueModelProperty(
                    parent: modelProperty,
                    containerKeyPath: containerKeyPath,
                    key: key,
                    valueKeyPath: valueKeyPath,
                    initialValue: initialValue
                ),
                persistence: persistence
            )
        }
    }

    /**
     Returns a managed, non-persisting child controller whose model is a value within a key value container within the
     calling controller.

     The method will return an existing controller for the value if found within its manager, or will build —and set up
     within its type's manager— a new controller based on the currently held value.

     The method may throw a `KeyValueModelProperty.ValueNotFoundError` if its container key points to no value
     whatsoever.
     - Warning: The controllers are managed by type and key, so make sure you only use managed controllers if the keys
     being used are unique within the context of the application. For example don't use an integer index as the key
     unless you're 100% sure that there is only one set of controllers of the type for the whole app.
     - Parameter containerKeyPath: A key path from the model to a key value container within. Use `\.self` if the model
     itself is the key value container.
     - Parameter containerKey: The key to access within the key value container pointed at by `containerKeyPath`.
     - Parameter valueKeyPath: The key path from the `container[containerKey]` to the actual value we want to control.
     If the container value itself is what we want just use `\.self`.
     - Returns: A controller whose model is the value at
     `model[keyPath: containerKeyPath][containerKey][keyPath: valueKeyPath]`.
     */
    internal func managedChildController<Container: KeyValueCollection, Value: Equatable, T: ManagedObject>(
        forValueWithinKeyValueContainerAtKeyPath containerKeyPath: WritableKeyPath<Model, Container>,
        containerKey key: Container.Key,
        valueKeyPath: WritableKeyPath<Container.Value, Value>
    ) throws -> T where T: Controller<Container.Key, Value, Void>, T.ID == Container.Key {
        try T.manager.controller(forID: key) {
            guard let initialValue = model[keyPath: containerKeyPath][key]?[keyPath: valueKeyPath] else {
                // We can't safely create a controller without an initial value.
                throw KeyValueModelProperty<Model, Container, Value>.ValueNotFoundInParentError(key: key)
            }

            return T(
                for: key,
                with: KeyValueModelProperty(
                    parent: modelProperty,
                    containerKeyPath: containerKeyPath,
                    key: key,
                    valueKeyPath: valueKeyPath,
                    initialValue: initialValue
                ),
                persistence: ()
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
     - Parameter persistence: The persistence to assing to the child controller. It's up to the surrounding logic to
     procure one of the right type.
     `model[keyPath: containerKeyPath][containerKey][keyPath: valueKeyPath]`.
     */
    func managedChildController<Container: KeyValueCollection, Value: Equatable, T: ManagedObject, P>(
        forValueWithinKeyValueContainerAtKeyPath containerKeyPath: WritableKeyPath<Model, Container>,
        containerKey key: Container.Key,
        valueKeyPath: WritableKeyPath<Container.Value, Value>,
        initialValue: Value,
        persistence: P
    ) -> T where T: Controller<Container.Key, Value, P>, T.ID == Container.Key {
        T.manager.controller(forID: key) {
            T(
                for: key,
                with: KeyValueModelProperty(
                    parent: modelProperty,
                    containerKeyPath: containerKeyPath,
                    key: key,
                    valueKeyPath: valueKeyPath,
                    initialValue: initialValue
                ),
                persistence: persistence
            )
        }
    }

    /**
     Returns a managed, non-persisting child controller whose model is a value within a key value container within the
     calling controller, or creates it otherwise.

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
     - Parameter persistence: The persistence to assing to the child controller. It's up to the surrounding logic to
     procure one of the right type.
     `model[keyPath: containerKeyPath][containerKey][keyPath: valueKeyPath]`.
     */
    func managedChildController<Container: KeyValueCollection, Value: Equatable, T: ManagedObject>(
        forValueWithinKeyValueContainerAtKeyPath containerKeyPath: WritableKeyPath<Model, Container>,
        containerKey key: Container.Key,
        valueKeyPath: WritableKeyPath<Container.Value, Value>,
        initialValue: Value
    ) -> T where T: Controller<Container.Key, Value, Void>, T.ID == Container.Key {
        T.manager.controller(forID: key) {
            T(
                for: key,
                with: KeyValueModelProperty(
                    parent: modelProperty,
                    containerKeyPath: containerKeyPath,
                    key: key,
                    valueKeyPath: valueKeyPath,
                    initialValue: initialValue
                ),
                persistence: ()
            )
        }
    }
}
