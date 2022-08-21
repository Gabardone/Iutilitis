//
//  Array+Autolayout.swift
//
//
//  Created by Óscar Morales Vivó on 8/20/22.
//

import Cocoa

public extension Array where Element == NSLayoutConstraint {
    /**
     Use this method for a more terse activation of an `Array` of layout constraint.
     */
    func activate() {
        NSLayoutConstraint.activate(self)
    }
}
