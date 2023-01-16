//
//  ControllerManager.swift
//  Teibolto Classic
//
//  Created by Óscar Morales Vivó on 12/30/22.
//

import Foundation

/**
 A protocol to implement by objects that want to be managed by an `ObjectManager`

 Due to limitations of the Swift type system, the implementations need to be `final` classes or an equivalent. For our
 current purposes that is not an issue.
 - Todo: Investigate ways to lift the limitations above while keeping the API simple to use.
 */
public protocol ManagedObject: AnyObject {
    associatedtype ID: Hashable

    static var manager: ObjectManager<ID, Self> { get }
}

/**
 A class to manage objects of a given kind.

 These have to be manually declared as singletons for each controller type (unfortunate generics limitations) but when
 used guarantee that you'll always get the same controller for the same ID.

 - Warning: The chosen `ID` type _must_ remain unique when converted to `String`, since it's being converted to
 `NSString` for use as the key for a `NSMapTable`
 - Todo: Lift the limitations on ID types once a better weak value container is found.
 */
public final class ObjectManager<ID: Hashable, ObjectType: AnyObject> {
    /// The default initializer is declared public.
    public init() {}

    public func controller(forID id: ID, builder: () throws -> ObjectType) rethrows -> ObjectType {
        let stringID = "\(id)" as NSString
        return try cache.object(forKey: stringID) ?? {
            let newController = try builder()
            cache.setObject(newController, forKey: stringID)
            return newController
        }()
    }

    // NSMapTable remains the one officially supported collection of weak items, so we'll live with its limitations.
    private let cache = NSMapTable<NSString, ObjectType>.strongToWeakObjects()
}
