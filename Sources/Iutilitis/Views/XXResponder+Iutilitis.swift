//
//  File.swift
//
//
//  Created by Óscar Morales Vivó on 12/24/22.
//

#if canImport(Cocoa)
import Cocoa

public extension NSResponder {
    /**
     Returns a sequence containing the responder chain starting at the calling instance.
     - Returns A sequence starting with `self` whose elements form the responder chain from `self`.
     */
    func responderChain() -> some Sequence {
        sequence(first: self, next: \.nextResponder)
    }
}

typealias XXResponder = NSResponder
#elseif canImport(UIKit)
import UIKit

public extension UIResponder {
    /**
     Returns a sequence containing the responder chain starting at the calling instance.
     - Returns A sequence starting with `self` whose elements form the responder chain from `self`.
     */
    func responderChain() -> some Sequence {
        sequence(first: self, next: \.next)
    }
}

typealias XXResponder = UIResponder
#endif

public extension XXResponder {
    /**
     Finds the next element in the responder chain of the given type, including oneself (call on `nextResponder` if you
     want to skip further down in the chain).
     - Parameter type: The type we're looking for. Can be either an actual class type (i.e. look for the closest
     ancestor of a containing view or view controller type). Or a protocol (useful for Swift-friendly responder chain
     action management).
     - Returns The closest responder down the chain of the requested type, or `nil` if none were found.
     */
    func firstResponder<T>(ofType _: T.Type) -> T? {
        for nextResponder in responderChain() {
            if let typecast = nextResponder as? T {
                return typecast
            }
        }

        return nil
    }
}
