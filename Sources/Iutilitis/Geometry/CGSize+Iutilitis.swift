//
//  CGSize+Iutilitis.swift
//
//
//  Created by Óscar Morales Vivó on 5/2/23.
//

import CoreGraphics

public extension CGSize {
    /**
     Returns the aspect ratio of the size, as `width / height`.

     If height is zero, returns `.infinity` as to avoid division by zero crashing. Check the result for `isInfinity` if
     you haven't validated otherwise.
     */
    var aspectRatio: CGFloat {
        guard height > 0.0 else { return .infinity }

        return width / height
    }
}
