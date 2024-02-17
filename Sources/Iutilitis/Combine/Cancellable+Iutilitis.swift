//
//  Cancellable+Iutilitis.swift
//
//
//  Created by Óscar Morales Vivó on 11/7/22.
//

import Combine
import Foundation

public extension Cancellable {
    /**
     Avoids needing to use `AnyCancellable` type to store subscriptions in arrays and other simple collections.
     */
    func store<C>(in collection: inout C) where C: RangeReplaceableCollection, C.Element == any Cancellable {
        collection.append(self)
    }
}

public extension Cancellable where Self: Hashable {
    /**
     May be useful to avoid using `AnyCancellable` to store subscriptions but only works if they are all of the same
     kind.
     */
    func store(in set: inout Set<Self>) {
        set.insert(self)
    }
}
