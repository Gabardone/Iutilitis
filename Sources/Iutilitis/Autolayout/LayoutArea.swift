//
//  LayoutArea.swift
//
//
//  Created by Óscar Morales Vivó on 8/20/22.
//

import Cocoa

/**
 While `NSView` and `NSLayoutGuide` both have the exact same layout anchor methods declared, the framework never
 declared a common protocol that they both implement so you could pass one into methods requiring the other.

 This protocol allows us to do just that for our autolayout utilities.
 - Note: `leftAnchor` and `rightAnchor` are _very explicitly_ omitted here. If you hit one of the very rare cases
 where you actually need to explicitly layout on left/right instead of leading/trailing just use the raw auto layout
 API.
 */
protocol LayoutArea {
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var centerXAnchor: NSLayoutXAxisAnchor { get }
    var centerYAnchor: NSLayoutYAxisAnchor { get }
    var heightAnchor: NSLayoutDimension { get }
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var widthAnchor: NSLayoutDimension { get }
}

extension LayoutArea {
    /**
     Returns constraints aligning the caller to another `LayoutArea`'s corresponding edges. Insets are applied as if
     the given `LayoutArea` is semantically enclosing the caller.

     For the common use cases of centering a `NSView` against its `superview`, use the corresponding wrapper method
     `NSView.constraintsAgainstSuperview(_:insets:)`
     - Precondition: Both the caller and `layoutArea` belong to the same layout hierarchy. There ought to be a semantic
     enclosing relation between them, although this isn't enforced in any way.
     - Parameter layoutArea: The enclosing layout area against whose edges the caller wants to constrain itself.
     - Parameter edges: The edges to constrain against. By default, all of them.
     - Parameter insets: Insets to apply between the caller and the enclosing layout area. Assuming an enclosing
     relationship, positive values make the caller smaller while negative values make the caller larger than the
     enclosing layout area.
     - Returns: An array with the generated layout constraints. Don't forget to activate them or store somewhere for
     later use.
     */
    func constraintsAgainstEnclosing(
        layoutArea: LayoutArea,
        edges: NSDirectionalRectEdge = .all,
        insets: NSDirectionalEdgeInsets = .zero
    ) -> [NSLayoutConstraint] {
        var result = [NSLayoutConstraint]()
        if edges.contains(.leading) {
            result.append(leadingAnchor.constraint(equalTo: layoutArea.leadingAnchor, constant: insets.leading))
        }
        if edges.contains(.top) {
            result.append(topAnchor.constraint(equalTo: layoutArea.topAnchor, constant: insets.top))
        }
        if edges.contains(.trailing) {
            result.append(layoutArea.trailingAnchor.constraint(equalTo: trailingAnchor, constant: insets.trailing))
        }
        if edges.contains(.bottom) {
            result.append(layoutArea.bottomAnchor.constraint(equalTo: bottomAnchor, constant: insets.bottom))
        }

        return result
    }

    /**
     Returns constraints that center the caller against the center of the given `LayoutArea`.

     For the common use case of a view being centered against its superview use `NSView.constraintsCenteringInSuperview`
     instead.
     - Precondition: Both the caller and `layoutArea` belong to the same layout hierarchy.
     - Parameter layoutArea: The layout area we want to center on.
     - Parameter horizontalOffset: An additional horizontal offset to apply. Defaults to 0.0 (fully centered)
     - Parameter verticalOffset: An additional vertical offset to apply. Defaults to 0.0 (fully centered)
     - Returns: An array with the constraints that center the caller against `layoutArea` with the given
     offsets applied.
     */
    func constraintsCenteringIn(
        layoutArea: LayoutArea,
        horizontalOffset: CGFloat = 0.0,
        verticalOffset: CGFloat = 0.0
    ) -> [NSLayoutConstraint] {
        [
            centerXAnchor.constraint(equalTo: layoutArea.centerXAnchor, constant: horizontalOffset),
            centerYAnchor.constraint(equalTo: layoutArea.centerYAnchor, constant: verticalOffset),
        ]
    }

    /**
     Returns the constraints for a fixed size for the caller.

     The returned constraints will fix the caller at the given size with a `.required` priority. Please avoid using
     these if `intrinsicContentSize` and content compression/hugging priorities can do the work instead.
     - Parameter size: The size we want the caller to maintain.
     - Returns: An array with the generated constraints.
     */
    func constraints(forFixedSize size: CGSize) -> [NSLayoutConstraint] {
        [
            widthAnchor.constraint(equalToConstant: size.width),
            heightAnchor.constraint(equalToConstant: size.height),
        ]
    }
}
