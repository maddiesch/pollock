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

// MARK: - Built in Types
extension CGSize : Serializable {
    public init(_ payload: [String : Any]) throws {
        guard let width = payload["width"] as? CGFloat else {
            throw SerializerError("Size missing width")
        }
        guard let height = payload["height"] as? CGFloat else {
            throw SerializerError("Size missing height")
        }
        self.init(width: width, height: height)
    }

    public func serialize() throws -> [String : Any] {
        return [
            "width": self.width,
            "height": self.height
        ]
    }
}

extension CGPoint : Serializable {
    public init(_ payload: [String : Any]) throws {
        guard let x = payload["x"] as? CGFloat else {
            throw SerializerError("Size missing width")
        }
        guard let y = payload["y"] as? CGFloat else {
            throw SerializerError("Size missing height")
        }
        self.init(x: x, y: y)
    }

    public func serialize() throws -> [String : Any] {
        return ["x": self.x, "y": self.y]
    }
}
