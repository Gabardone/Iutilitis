//
//  File.swift
//
//
//  Created by Óscar Morales Vivó on 12/24/22.
//

import Foundation

public extension Comparable {
    /**
     Clamps a value to a given closed range of the same type.

     The returned value will be contained within the given range. If the caller was not already contained in the range,
     the result will be the closest value that is.
     - Parameter range: The closed range that we want the clamp the calling value to. Results for an empty range are
     undefined.
     */
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(range.lowerBound, self), range.upperBound)
    }
}

public extension Comparable where Self: Strideable & ExpressibleByIntegerLiteral {
    /**
     Clamps a value to a given range of the same type.

     The returned value will be contained within the given range. If the caller was not already contained in the range,
     the result will be the closest value that is.
     - Parameter range: The range that we want the clamp the calling value to. Results for an empty range are undefined.
     */
    func clamped(to range: Range<Self>) -> Self {
        min(max(range.lowerBound, self), range.upperBound.advanced(by: -1))
    }
}
