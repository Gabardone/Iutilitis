//
//  File.swift
//  
//
//  Created by Óscar Morales Vivó on 4/3/23.
//

import Foundation

public extension Optional where Wrapped: Collection {
    /**
     Checks whether the optional is both non-`nil` and not-`empty`.

     Quick verification for whether a collection optional has any contents. A `nil` collection optional by definition
     does not.

     Works for Strings as well!
     */
    @inlinable
    var hasContents: Bool {
        return map { !$0.isEmpty } ?? false
    }

    /**
     Unwraps a collection optional only if it's not empty.

     If you want to unwrap a collection optional —say for an `if let` statement where you'd do a bunch of things if
     there's anything to do a bunch of things _to_— _and_ check if it's empty, you could as well use this utility to
     get the unwrapped value _only_ if there are contents to deal with.

     Works for Strings as well!
     */
    @inlinable
    var contents: Wrapped? {
        return flatMap { $0.isEmpty ? nil : $0 }
    }
}
