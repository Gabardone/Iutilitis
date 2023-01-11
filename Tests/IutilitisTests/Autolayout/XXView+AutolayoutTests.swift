//
//  XXView+AutolayoutTests.swift
//
//
//  Created by Óscar Morales Vivó on 1/10/23.
//

@testable import Iutilitis
import XCTest

final class XXViewAutolayoutTests: XCTestCase {
    // Verifies the API contract for XXView.add(subview:)
    func testAddSubview() {
        let superview = XXView()
        let bottomSubview = XXView()
        let topSubview = XXView()

        superview.add(subview: bottomSubview)
        superview.add(subview: topSubview)

        XCTAssertFalse(bottomSubview.translatesAutoresizingMaskIntoConstraints)
        XCTAssertFalse(topSubview.translatesAutoresizingMaskIntoConstraints)
        XCTAssertEqual(superview.subviews.first, bottomSubview)
        XCTAssertEqual(superview.subviews.last, topSubview)
    }

    #if os(macOS)
        // Verifies the API contract for NSView.add(subview:positioned:relativeTo:)
        func testAddSubviewPositionedRelativeTo() {
            let superview = NSView()
            let middleSubview = NSView()
            let bottomSubview = NSView()
            let topSubview = NSView()

            superview.add(subview: topSubview)
            superview.add(subview: bottomSubview, positioned: .below, relativeTo: nil)
            superview.add(subview: middleSubview, positioned: .above, relativeTo: bottomSubview)

            XCTAssertFalse(topSubview.translatesAutoresizingMaskIntoConstraints)
            XCTAssertFalse(bottomSubview.translatesAutoresizingMaskIntoConstraints)
            XCTAssertFalse(middleSubview.translatesAutoresizingMaskIntoConstraints)
            XCTAssertEqual(superview.subviews.first, bottomSubview)
            XCTAssertEqual(superview.subviews[1], middleSubview)
            XCTAssertEqual(superview.subviews.last, topSubview)
        }
    #endif

    #if os(iOS)
        // Verifies the API contract for UIView.insert(subview:at:)
        func testInsertSubviewAt() {
            let superview = UIView()
            let middleSubview = UIView()
            let bottomSubview = UIView()
            let topSubview = UIView()

            superview.add(subview: topSubview)
            superview.insert(subview: bottomSubview, at: 0)
            superview.insert(subview: middleSubview, at: 1)

            XCTAssertFalse(topSubview.translatesAutoresizingMaskIntoConstraints)
            XCTAssertFalse(bottomSubview.translatesAutoresizingMaskIntoConstraints)
            XCTAssertFalse(middleSubview.translatesAutoresizingMaskIntoConstraints)
            XCTAssertEqual(superview.subviews.first, bottomSubview)
            XCTAssertEqual(superview.subviews[1], middleSubview)
            XCTAssertEqual(superview.subviews.last, topSubview)
        }

        // Verifies the API contract for UIView.insert(subview:belowSubview:)
        func testInsertSubviewBelowSubview() {
            let superview = UIView()
            let middleSubview = UIView()
            let bottomSubview = UIView()
            let topSubview = UIView()

            superview.add(subview: topSubview)
            superview.insert(subview: bottomSubview, belowSubview: topSubview)
            superview.insert(subview: middleSubview, belowSubview: topSubview)

            XCTAssertFalse(topSubview.translatesAutoresizingMaskIntoConstraints)
            XCTAssertFalse(bottomSubview.translatesAutoresizingMaskIntoConstraints)
            XCTAssertFalse(middleSubview.translatesAutoresizingMaskIntoConstraints)
            XCTAssertEqual(superview.subviews.first, bottomSubview)
            XCTAssertEqual(superview.subviews[1], middleSubview)
            XCTAssertEqual(superview.subviews.last, topSubview)
        }

        // Verifies the API contract for UIView.insert(subview:aboveSubview:)
        func testInsertSubviewAboveSubview() {
            let superview = UIView()
            let middleSubview = UIView()
            let bottomSubview = UIView()
            let topSubview = UIView()

            superview.add(subview: bottomSubview)
            superview.insert(subview: topSubview, aboveSubview: bottomSubview)
            superview.insert(subview: middleSubview, aboveSubview: bottomSubview)

            XCTAssertFalse(topSubview.translatesAutoresizingMaskIntoConstraints)
            XCTAssertFalse(bottomSubview.translatesAutoresizingMaskIntoConstraints)
            XCTAssertFalse(middleSubview.translatesAutoresizingMaskIntoConstraints)
            XCTAssertEqual(superview.subviews.first, bottomSubview)
            XCTAssertEqual(superview.subviews[1], middleSubview)
            XCTAssertEqual(superview.subviews.last, topSubview)
        }
    #endif
}
