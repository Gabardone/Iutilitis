//
//  NSView+Autolayout.swift
//
//
//  Created by Óscar Morales Vivó on 8/20/22.
//

import Cocoa

extension NSView {
    /**
     Use instead of `addSubview(_:)` to add a subview to the caller's subview array.

     Management of the `translatesAutoresizingMaskIntoConstraints` flag is responsibility of its `superview`, so it
     makes the most sense to turn it off upon insertion to a view hierarchy. Other than that this method works the exact
     same as `addSubview(_:)`

     The method uses a short, nonspecific name as it's meant to be the default one to use, plus `addArrangedSubview` was
     already taken.
     - Parameter view: The view to add at the end of the subview array, to be laid out using autolayout.
     - Note: For standardized autolayout usage it's best to declare a linter rule that triggers whenever `addSubview` is
     used. The few cases where fully manual layout is warranted can turn the rule off.
     */
    func add(subview view: NSView) {
        view.translatesAutoresizingMaskIntoConstraints = false // swiftlint:disable:this avoid_manually_disabling_TARMiC
        addSubview(view) // swiftlint:disable:this avoid_addsubview
    }

    /**
     Use instead of `addSubview(_:positioned:relativeTo:)` to add a subview to the caller's subview array at the
     specified position.

     Management of the `translatesAutoresizingMaskIntoConstraints` flag is responsibility of its `superview`, so it
     makes the most sense to turn it off upon insertion to a view hierarchy. Other than that this method works the exact
     same as `addSubview(_:positioned:relativeTo:)`

     The method uses a short, nonspecific name as it's meant to be the default one to use, plus `insertArrangedSubview`
     was already taken.
     - Parameter view: The view to add at the end of the subview array, to be laid out using autolayout.
     - Note: For standardized autolayout usage it's best to declare a linter rule that triggers whenever `addSubview` is
     used. The few cases where fully manual layout is warranted can turn the rule off.
     */
    func add(subview view: NSView, positioned place: NSWindow.OrderingMode, relativeTo otherView: NSView?) {
        view.translatesAutoresizingMaskIntoConstraints = false // swiftlint:disable:this avoid_manually_disabling_TARMiC
        addSubview(view, positioned: place, relativeTo: otherView) // swiftlint:disable:this avoid_addsubview
    }
}
