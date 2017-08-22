//
//  Serializable.swift
//  Pollock
//
//  Created by Skylar Schipper on 4/27/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

public protocol Serializable {
    func serialize() throws -> [String: Any]

    init(_ payload: [String: Any]) throws
}

extension Serializable {
    static func load(_ object: Any?) throws -> Self {
        guard let payload = object as? [String: Any] else {
            throw SerializerError("Invalid object. Can't load \(type(of: Self.self))")
        }
        return try Self(payload)
    }
}
