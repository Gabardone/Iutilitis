//
//  FlippedView.swift
//
//
//  Created by Óscar Morales Vivó on 8/21/22.
//

#if canImport(Cocoa)
    import Cocoa

    /**
     A dummy coordinate system-flipped view for use in macOS layouts when needed, either on its own to avoid
     overcomplicating layout calculations or as a superclass for other views that are significantly easier to implement on
     a top-to-bottom coordinate system.
     */
    open class FlippedView: NSView {
        override public var isFlipped: Bool {
            true
        }
    }
#endif
