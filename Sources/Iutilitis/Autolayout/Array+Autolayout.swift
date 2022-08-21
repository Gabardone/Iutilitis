//
//  Array+Autolayout.swift
//
//
//  Created by Óscar Morales Vivó on 8/20/22.
//

import Cocoa

extension Array where Element == NSLayoutConstraint {
    /**
     Use this method for a more terse activation of an `Array` of layout constraint.

     It also returns `self` so it can be further chained or sent as a parameter to other methods.
     */
    @discardableResult @inlinable
    public func activate() -> Self {
        NSLayoutConstraint.activate(self)
        return self
    }
}
