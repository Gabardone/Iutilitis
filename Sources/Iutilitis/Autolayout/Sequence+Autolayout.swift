//
//  Sequence+Autolayout.swift
//  
//
//  Created by Óscar Morales Vivó on 8/20/22.
//

import Cocoa

extension Sequence where Element == NSLayoutConstraint {
    /**
     Use this method for a more terse activation of an `Array` of layout constraint.
     */
    @inlinable
    public func activate() {
        Array(self).activate()
    }

    /**
     Sets the priority of all the constraints in the array to the given one.

     Priority changes obey the same rules as if done individually, so avoid changing from/to `.required` priority for
     active constraints.
     - Parameter priority: The new priority for all the constraints in the array.
     - Returns: `self`, so it can be used as one of a series of chained calls.
     */
    @discardableResult @inlinable
    public func priority(_ priority: NSLayoutConstraint.Priority) -> Self {
        for constraint in self {
            constraint.priority = priority
        }

        return self
    }
}
