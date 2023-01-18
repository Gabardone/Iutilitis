//
//  ModelProperty.swift
//  Teibolto Classic
//
//  Created by Óscar Morales Vivó on 12/11/22.
//

import Combine
import Foundation

/**
 A wrapper that allows for access, modification and subscription to a model's updates.

 `ModelProperty` implementations are meant to be used to feed `Controller` instances, although the type may also be
 useful any time where there's need to abstract away together access to, editing of and update notification from a
 particular piece of data.

 Hiding away the actual implementation allows a great deal of flexibility for testing as well as building up more
 complex model structures that can be controller piecemeal.
 */
public protocol ModelProperty<Model> {
    /// The model type the property wraps.
    associatedtype Model: Equatable

    /// The current value of the model, accessible synchronously.
    var value: Model { get }

    /// Convenience `typealias` for the publisher used to broadcast value updates.
    typealias UpdatePublisher = AnyPublisher<Model, Error>

    /**
     A publisher that calls its subscribers when `value` changes, and _only_ when `value` changes.

     Implementations are responsible for short-circuiting spurious publisher updates through equality gating.
     - Todo: Revisit using `any Publisher<...>` instead of `AnyPublisher` if Combine becomes friendlier with
     existentials.
     */
    var updatePublisher: UpdatePublisher { get }

    /**
     Updates `value` to the given one.

     The method is allowed to throw if the new value is not valid for whatever reason or the update cannot otherwise
     be performed.
     - Parameter newValue: The new value we wish `value` to take, if nothing prevents it.
     */
    mutating func updateValue(to newValue: Model) throws
}
