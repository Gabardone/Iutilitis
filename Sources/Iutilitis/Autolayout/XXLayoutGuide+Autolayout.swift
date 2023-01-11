//
//  NSLayoutGuide+Autolayout.swift
//
//
//  Created by Óscar Morales Vivó on 8/20/22.
//

#if canImport(Cocoa)
    import Cocoa

    extension NSLayoutGuide: LayoutArea {}
#elseif canImport(UIKit)
    import UIKit

    extension UILayoutGuide: LayoutArea {}
#endif
