//
//  Model.swift
//
//
//  Created by Óscar Morales Vivó on 9/2/23.
//

import Foundation

public struct Model<ID, Properties> {
    public var id: ID

    public var properties: Properties
}

extension Model: Identifiable where ID: Hashable {}

extension Model: Codable where ID: Codable, Properties: Codable {}

extension Model: Equatable where ID: Equatable, Properties: Equatable {}

extension Model: Hashable where ID: Hashable, Properties: Hashable {}
