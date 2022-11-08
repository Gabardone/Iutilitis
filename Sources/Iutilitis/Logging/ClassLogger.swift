//
//  ClassLogger.swift
//
//
//  Created by Óscar Morales Vivó on 11/7/22.
//

import Foundation
import os

/**
 Returns a logger for a specific class.
 */
public extension Logger {
    init<T: AnyObject>(forClass _: T.Type) {
        self.init(
            subsystem: Bundle(for: T.self).bundleIdentifier ?? Bundle.main.bundleIdentifier ?? "Unknown Bundle",
            category: String(describing: T.self)
        )
    }
}
