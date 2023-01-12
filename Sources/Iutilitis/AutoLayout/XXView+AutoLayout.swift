//
//  XXView+AutoLayout.swift
//
//
//  Created by Óscar Morales Vivó on 8/20/22.
//

#if canImport(Cocoa)
    import Cocoa

    public extension NSView {
        /**
         Use instead of `addSubview(_:positioned:relativeTo:)` to add a subview to the caller's subview array at the
         specified position.

         Management of the `translatesAutoresizingMaskIntoConstraints` flag is responsibility of its `superview`, so it
         makes the most sense to turn it off upon insertion to a view hierarchy. Other than that this method works the exact
         same as `addSubview(_:positioned:relativeTo:)`

         The method uses a short, nonspecific name as it's meant to be the default one to use, plus `insertArrangedSubview`
         was already taken.
         - Parameter subview: The view to add at the end of the subview array, to be laid out using AutoLayout.
         - Parameter place: Ordering of the subview relative to `otherView`. See the relevant documentation for
         `NSView.addSubview(_:positioned:relativeTo:)` for more information.
         - Parameter otherView: Existing subview relative to which `subview` will be inserted. If nil, the subview will
         be inserted at the top or bottom depending on the value of `place`. See the relevant documentation for
         `NSView.addSubview(_:positioned:relativeTo:)` for more information.
         - Note: For standardized AutoLayout usage it's best to declare a linter rule that triggers whenever `addSubview` is
         used. The few cases where fully manual layout is warranted can turn the rule off.
         */
        func add(subview: XXView, positioned place: NSWindow.OrderingMode, relativeTo otherView: XXView?) {
            subview.translatesAutoresizingMaskIntoConstraints = false // swiftlint:disable:this avoid_manually_disabling_TARMiC
            addSubview(subview, positioned: place, relativeTo: otherView) // swiftlint:disable:this avoid_addsubview
        }

        /**
         Wrapper for `layoutSubtreeIfNeeded` to use the UIKit name.

         In this case the UIKit name is less confusing, although the methods don't act exactly the same on either
         platforms. The differences, hoaever, seem to be only noticeable in contrived scenarios.
         */
        @inlinable
        func layoutIfNeeded() {
            layoutSubtreeIfNeeded()
        }
    }

    public typealias XXView = NSView
#elseif canImport(UIKit)
    import UIKit

    public extension UIView {
        /**
         Use instead of `insertSubview(_:at:)` to insert a subview in the caller's subview array at the specified index.

         Management of the `translatesAutoresizingMaskIntoConstraints` flag is responsibility of its `superview`, so it
         makes the most sense to turn it off upon insertion to a view hierarchy. Other than that this method works the exact
         same as `insertSubview(_:at:)`

         The method uses a short, nonspecific name as it's meant to be the default one to use, plus `insertArrangedSubview`
         was already taken.
         - Parameter subview: The view to add at the end of the subview array, to be laid out using AutoLayout.
         - Parameter index: The index within the subview array where `subview` will end. See the relevant documentation for
         `UIView.insertSubview(_:at:)` for more information.
         - Note: For standardized AutoLayout usage it's best to declare a linter rule that triggers whenever `addSubview` is
         used. The few cases where fully manual layout is warranted can turn the rule off.
         */
        func insert(subview: UIView, at index: Int) {
            subview.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(subview, at: index)
        }

        /**
         Use instead of `insertSubview(_:aboveSubview:)` to insert a subview in the caller's subview array at the
         specified position.

         Management of the `translatesAutoresizingMaskIntoConstraints` flag is responsibility of its `superview`, so it
         makes the most sense to turn it off upon insertion to a view hierarchy. Other than that this method works the exact
         same as `insertSubview(_:aboveSubview:)`

         The method uses a short, nonspecific name as it's meant to be the default one to use, plus `insertArrangedSubview`
         was already taken.
         - Parameter subview: The view to insert at the specified position in the subview array, to be laid out using
         AutoLayout.
         - Parameter aboveSubview: Existing subview above which `subview` should be inserted. Check the documentation of
         `UIView.insertSubview(_:aboveSubview:)` for more information.
         - Note: For standardized AutoLayout usage it's best to declare a linter rule that triggers whenever `insertSubview`
         is used. The few cases where fully manual layout is warranted can turn the rule off.
         */
        func insert(subview: UIView, aboveSubview siblingSubview: UIView) {
            subview.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(subview, aboveSubview: siblingSubview)
        }

        /**
         Use instead of `insertSubview(_:belowSubview:)` to insert a subview in the caller's subview array at the
         specified position.

         Management of the `translatesAutoresizingMaskIntoConstraints` flag is responsibility of its `superview`, so it
         makes the most sense to turn it off upon insertion to a view hierarchy. Other than that this method works the exact
         same as `insertSubview(_:belowSubview:)`

         The method uses a short, nonspecific name as it's meant to be the default one to use, plus `insertArrangedSubview`
         was already taken.
         - Parameter subview: The view to insert at the specified position in the subview array, to be laid out using
         AutoLayout.
         - Parameter belowSubview: Existing subview below which `subview` should be inserted. Check the documentation of
         `UIView.insertSubview(_:belowSubview:)` for more information.
         - Note: For standardized AutoLayout usage it's best to declare a linter rule that triggers whenever `insertSubview`
         is used. The few cases where fully manual layout is warranted can turn the rule off.
         */
        func insert(subview: UIView, belowSubview siblingSubview: UIView) {
            subview.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(subview, belowSubview: siblingSubview)
        }
    }

    public typealias XXView = UIView
#endif

public extension XXView {
    /**
     Use instead of `addSubview(_:)` to add a subview to the caller's subview array.

     Management of the `translatesAutoresizingMaskIntoConstraints` flag is responsibility of its `superview`, so it
     makes the most sense to turn it off upon insertion to a view hierarchy. Other than that this method works the exact
     same as `addSubview(_:)`

     The method uses a short, nonspecific name as it's meant to be the default one to use, plus `addArrangedSubview` was
     already taken.
     - Parameter subview: The view to add at the end of the subview array, to be laid out using AutoLayout.
     - Note: For standardized AutoLayout usage it's best to declare a linter rule that triggers whenever `addSubview` is
     used. The few cases where fully manual layout is warranted can turn the rule off.
     */
    func add(subview: XXView) {
        subview.translatesAutoresizingMaskIntoConstraints = false // swiftlint:disable:this avoid_manually_disabling_TARMiC
        addSubview(subview) // swiftlint:disable:this avoid_addsubview
    }
}

/**
 NSView implements the `LayoutArea` protocol, but it still needs declaring in Swift.
 */
extension XXView: LayoutArea {}

public extension XXView {
    /**
     Constraint generator for a view against its superview edges.

     The method will return an array of the constraints between the calling view and its superview edges with an
     inset equal to that specified in the given directional edge insets.

     For height/width constraints against superview, just use the regular width/height constraint anchor API.
     - Precondition: The calling view must have a superview.
     - Parameter edges: The edges against which we want to snap our view to its superview. By default the method
     generates constraints in all directions.
     - Parameter insets: The inset between the superview and the calling view to be applied in the returned
     constraints. Only the ones called for in the `edges` parameters will be used. By default on insets are applied.
     - Returns: An array with the generated constraints.
     */
    func constraintsAgainstSuperviewEdges(
        _ edges: NSDirectionalRectEdge = .all,
        insets: NSDirectionalEdgeInsets = .zero
    ) -> [NSLayoutConstraint] {
        guard let superview = superview else {
            preconditionFailure("Attempted to create constraints against superview with no superview set.")
        }

        return constraintsAgainstEnclosing(layoutArea: superview, edges: edges, insets: insets)
    }

    /**
     Constraint generator to center a view within its superview.

     The returned constraints when activated will keep the caller centered within its superview.
     - Precondition: The calling view must have a superview.
     - Parameter offsets: Optional offsets to apply to the returned constraints. Default to zero.
     - Returns: An array with the generated constraints.
     */
    func constraintsCenteringInSuperview(
        horizontalOffset: CGFloat = 0.0,
        verticalOffset: CGFloat = 0.0
    ) -> [NSLayoutConstraint] {
        guard let superview = superview else {
            preconditionFailure("Attempted to create constraints against superview with no superview set.")
        }

        return constraintsCenteringIn(
            layoutArea: superview,
            horizontalOffset: horizontalOffset,
            verticalOffset: verticalOffset
        )
    }
}
