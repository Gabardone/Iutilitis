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

 `Persistence` is the type that will be used for persisting edits, fetching data and obtaining data updates. It's
 left undetermined as the needs of various controllers vary wildly, but should almost always be a protocol type as to
 allow for easy mocking in tests. Common functionality will be provided with adoptable protocols for those persistence
 types that bring controller utilities via `extension Controller where Persistence: SomeProtocol`

 In some cases (i.e. simple UI display of existing data) there's no need for a persistence type altogether. Use `Void`
 to intantiate the controller type in those cases.
 - Todo: Consider building a controller manager (hard to do right with Swift's limitations on generics. May need to
 make them injectable).
 */
open class Controller<ID: Hashable, Model: Equatable, Persistence>: Identifiable, ObservableObject {
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
    public required init<T: ModelProperty>(
        for id: ID,
        with modelProperty: T,
        initialValue: Model,
        persistence: Persistence
    ) where T.Model == Model {
        self.id = id
        self.model = initialValue
        self.modelProperty = modelProperty
        self.persistence = persistence

        // Make sure updates on the abstract model property reflect on the stored property. If there's an error
        // upstream we just stop updating since `@Published` doesn't support errors.
        modelProperty.updatePublisher
            .catch { [weak self] error in
                controllerLogger.error("Controller \(String(describing: self)) received update error from model property \(String(describing: modelProperty)). Error: \(error.localizedDescription)")
                return Empty<Model, Never>()
            }
            .assign(to: &$model)
    }

    public typealias ID = ID

    public typealias Model = Model

    public typealias Persistence = Persistence

    /// The controller's unique ID for the type.
    public let id: ID

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
    public private(set) var model: Model

    /**
     The persistence used by the controller to persist edits and fetch data.

     While it should _not_ be used from the outside, access is often needed to build up persistence for child
     controllers. How that goes is dependent on the specific persistence implementation.
     */
    public let persistence: Persistence

    /**
     The model property that the controller is managing. Accessed within the module to implement child controller
     creation utilities, but don't access it directly otherwise.
     */
    internal var modelProperty: any ModelProperty<Model>
}

// MARK: - Editing

public extension Controller {
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
