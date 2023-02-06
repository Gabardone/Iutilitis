//
//  ModelProperty.swift
//  Teibolto Classic
//
//  Created by Óscar Morales Vivó on 12/11/22.
//

import Combine
import Foundation

/**
 Validates a proposes value for the model property. The block should throw if the value would not be a valid one
 to send to the model property's setter block.

 Recoverability and value suggestions can be implemented through custom `Error` types.

 Any additional context needed for validation should be captured within the validator block.
 */
public typealias Validator<Model> = (Model) throws -> Void

/**
 A wrapper for a property's full set of behaviors including, optionally, validation.

 `ModelProperty` set ups are meant to be used to feed `Controller` instances but they can also be used on their own
 when you need an abstraction for a property and none of the ones in the library fulfills all your needs just right.

 Most of the time these will be built up or composed with the provided factory constructors but building a custom one
 for specific needs isn't particularly difficult.
 - Note: Many of the composed model properties follow a parent-child relation, requiring references to an original
 model property that holds the data that the "child" one extracts its own model from.

 For these use cases strong references should follow the same direction as similar APIs i.e. Combine. As long as there
 are no references from a parent model property to its children and only in the opposite direction reference cycles
 should be avoided.
 */
public struct ModelProperty<Model: Equatable> {
    // MARK: - Types

    /**
     A block that retrieves the data held by the `ModelProperty` value. It is expected to always work and do so
     quickly. If your data is asynchronous or could error on fetch, use something else —and maybe move to
     `ModelProperty` once you successfully got it.
     */
    public typealias Getter = () -> Model

    /**
     A block that sets the model property data to the given one.

     This behavior is apart from validation, and is expected to only be called _after_ validation is successful. If an
     invalid value is sent in the behavior of the model property from that point is undefined.
     */
    public typealias Setter = (Model) -> Void

    /**
     The type of publisher used to broadcast value updates.

     An `UpdatePublisher` is meant to _only_ emit when the value actually changes. Subscription shouldn't cause a value
     to be emitted to the subscriber (unlike, say a `@Published` property).

     Since all values held by a `ModelProperty` are meant to implement `Equatable`, these publishers are meant to gate
     against emitting the same value more than once in a row, either by using `removeDuplicates` or other logic.
     */
    public typealias UpdatePublisher = AnyPublisher<Model, Never>

    // MARK: - Initialization.

    /**
     Fully sets up a `ModelProperty`

     You usually won't want to use this one directly, opting instead for the various factory setup methods provided. If
     you require a fully custom `ModelProperty` then eventually you'll want to call this with all the blocks setting up
     its various behaviors.
     - Parameter updatePublisher: A publisher that emits whenever the property value changes, and _only_ when the
     property value changes.
     - Parameter getter: A block that gets the property value.
     - Parameter setter: A block that sets the property to the given value. No validation performed, behavior undefined
     if the value is not valid.
     - Parameter validator: A block that validates a proposed value. If the value would be valid to set the block
     returns, otherwise it throws an exception. If you do not want to validate at all just pass `{ _ in }` to this
     parameter. This is sadly necessary to avoid the compiler being confused by default validatable extensions.
     */
    public init(
        updatePublisher: UpdatePublisher,
        getter: @escaping Getter,
        setter: @escaping Setter,
        validator: @escaping Validator<Model> = emptyValidator()
    ) {
        self.updatePublisher = updatePublisher
        self.getter = getter
        self.setter = setter
        self.validator = validator
    }

    // MARK: - Properties

    /**
     A publisher that calls its subscribers when `value` changes, and _only_ when `value` changes.

     Implementations are responsible for short-circuiting spurious publisher updates through equality gating.
     - Todo: Revisit using `any Publisher<...>` instead of `AnyPublisher` if Combine becomes friendlier with
     existentials.
     */
    public let updatePublisher: UpdatePublisher

    private let getter: Getter

    private let setter: Setter

    private let validator: Validator<Model>

    // MARK: - Public API

    /// The current value of the model, accessible synchronously.
    public var value: Model {
        getter()
    }

    /**
     Updates `value` to the given one.

     The method does no validation on `newValue`. If validation is desired, use the corresponding method before calling
     this one.
     - Parameter newValue: The new value we wish `value` to take.
     */
    public func updateValue(_ newValue: Model) {
        guard value != newValue else {
            return
        }

        setter(newValue)
    }

    /**
     Validates the proposed value as a valid one to send to `updateValue`

     The method throws if validation fails. This allows the implementation flexibility when it comes to reporting
     further information about why validation failed, as well as encapsulating other behaviors such as retry logic or
     alternate value suggestions.
     - Parameter proposedValue: A value. If the method doesn't throw, the value is a valid parameter for `updateValue`.
     */
    public func validate(proposedValue: Model) throws {
        try validator(proposedValue)
    }
}

// MARK: - Utilities

public extension ModelProperty {
    /**
     Returns an empty validator for the model property type that will let everything through.

     Use with care. Not a static property because Swift won't allow stored static properties on generic types.
     */
    static func emptyValidator<T>() -> Validator<T> {
        { _ in }
    }
}

// MARK: - Validatable Utilities

public extension ModelProperty where Model: Validatable {
    /**
     Default model property setup for validatable model types.

     For validatable types we default the validator to running the `validate` method on the new value.
     - Parameter updatePublisher: A publisher that emits whenever the property value changes, and _only_ when the
     property value changes.
     - Parameter getter: A block that gets the property value.
     - Parameter setter: A block that sets the property to the given value. No validation performed, behavior undefined
     if the value is not valid.
     */
    init(
        updatePublisher: UpdatePublisher,
        getter: @escaping Getter,
        setter: @escaping Setter
    ) {
        self.updatePublisher = updatePublisher
        self.getter = getter
        self.setter = setter
        self.validator = { newValue in
            try newValue.validate()
        }
    }
}
