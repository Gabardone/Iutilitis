//
//  File.swift
//  Teibolto Classic
//
//  Created by Óscar Morales Vivó on 12/8/22.
//

import Foundation

public protocol Validatable {
    /**
     Validates the state of the caller.

     Use this method to check whether the caller is in a valid state. What that means depends on the type. Call
     liberally, but assume that data may not be valid at certain times (halfway through an edit, during intialization
     etc.).

     The method isn't meant to offer a full diagnostic of what's wrong. If there's several things wrong with the
     caller's state the method ought to nonetheless just throw the first one it finds. Callers shouldn't count on the
     order on various validation checks are done.
     */
    func validate() throws
}

extension Validatable {
    /**
     Default implementation of Validatable assumes validity of the caller. This is to allow for piecemeal construction
     of validatable flows but shouldn't be taken for granted.
     */
    func validate() throws {
        // This method intentionally left empty.
    }

    /**
     Simple utility to check whether a value is valid without having to deal with `try/catch`.
     */
    @inlinable
    var isValid: Bool {
        // This looks a little weird but is valid and what we want.
        (try? validate()) != nil
    }

    /**
     Simple assertion utility for `Validatable` types.

     Its behavior should be the same as `assert` and not execute any validation for release builds

     The method takes file and line parameters as to reflect the call site, not this utility, when a validation failure
     occurs. They should almost never need to be manually filled.
     */
    @inlinable
    func assertValid(file: StaticString = #file, line: UInt = #line) {
        var validationError: (any Error)?
        assert(
            {
                do {
                    try validate()
                    return true
                } catch {
                    validationError = error
                    return false
                }
            }(),
            "\(self) is in an invalid state. Error: \(validationError!.localizedDescription)",
            file: file,
            line: line
        )
    }
}

/**
 A generic validation error.

 There is no imperative to use this type when throwing errors during validation, but it makes for an easy throw if
 nothing more specific is forthcoming.
 */
struct ValidationError<T> {
    var invalidValue: T

    var reason: String?
}

extension ValidationError: Error {
    /**
     The `localizedDescription` implementation for `ValidationError` makes it unlikely to be useful for user display.
     But should be nice for debugging purposes.
     */
    var localizedDescription: String {
        // TODO: Make localizable.
        "Validation failed for \(String(describing: invalidValue))." + (reason.map { " Reason: \($0)" } ?? "")
    }
}

extension Validatable {
    func validateProperty(at keyPath: WritableKeyPath<Self, some Validatable>) throws {
        do {
            try self[keyPath: keyPath].validate()
        } catch {
            throw ValidationError(
                invalidValue: self[keyPath: keyPath],
                reason: "Property \(keyPath) failed validation with error \(error)"
            )
        }
    }
}
