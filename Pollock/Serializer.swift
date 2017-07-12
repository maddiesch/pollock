//
//  Serializer.swift
//  Pollock
//
//  Created by Skylar Schipper on 5/11/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

struct Serializer {
    static func serialize(context: Context, compress: Bool) throws -> Data {
        let output = try context.serialize()
        let data = try JSONSerialization.data(withJSONObject: output, options: [])
        if compress {
            return try data.zip()
        }
        return data
    }

    static func unserialize(data: Data) throws -> Context {
        let raw = try self.createRawData(data)
        guard let json = try JSONSerialization.jsonObject(with: raw, options: []) as? [String: Any] else {
            throw SerializerError("JSON format invalid")
        }
        return try Context(json)
    }

    private static func createRawData(_ data: Data) throws -> Data {
        if data.isZip {
            return try data.unzip()
        } else {
            return data
        }
    }

    @discardableResult
    internal static func validateVersion(_ version: Any?, _ ctx: String) throws -> PollockVersion {
        guard let num = version as? Int else {
            throw SerializerError("Invalid version number for \(ctx)")
        }
        guard PollockSupportedVersions.contains(num) else {
            throw SerializerError("Unsupported Version \(num) for \(ctx)")
        }
        return num
    }

    internal static func decodeUUID(_ obj: Any?) throws -> UUID {
        guard let uuidString = obj as? String else {
            throw SerializerError("Missing UUID")
        }
        guard let uuid = UUID(uuidString: uuidString) else {
            throw SerializerError("\(uuidString) is not a valid UUID")
        }
        return uuid
    }
}

public struct SerializerError : CustomNSError {
    public let message: String

    public var errorUserInfo: [String: Any] {
        return [
            NSLocalizedDescriptionKey: self.message
        ]
    }

    init(_ message: String) {
        self.message = message
    }
}
