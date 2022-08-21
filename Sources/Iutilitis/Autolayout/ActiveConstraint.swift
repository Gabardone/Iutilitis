//
//  ActiveConstraint.swift
//  
//
//  Created by Óscar Morales Vivó on 8/20/22.
//

import Cocoa

/**
 Property wrapper for a single active constraint.

 This property wrapper facilitates swapping a single constraint for different layout configurations.

 There is no good way to enforce that a constraint isn't activated or deactivated anywhere else so it's best to
 keep use of this property wrapper to the `private` implementation of another type, usually a `NSViewController` or
 `NSView` subclass.
  */
@propertyWrapper
struct ActiveConstraint {
    private var constraint: NSLayoutConstraint?

    var wrappedValue: NSLayoutConstraint? {
        get {
            return constraint
        }

        set {
            guard constraint != newValue else {
                return
            }

            constraint?.isActive = false
            constraint = newValue
            constraint?.isActive = true
        }
    }
}
