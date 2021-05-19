//
//  Serializer.swift
//  Pollock
//
//  Created by Skylar Schipper on 5/11/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import PencilKit

struct Serializer {
    @available(iOS 13.0, *)
    static func downConvert(pkdrawing: PKDrawing, compress: Bool) throws -> Data {
        let output = try pkdrawing.serialize()
        let data = try JSONSerialization.data(withJSONObject: output, options: [])
        if compress {
            return try data.zip()
        }
        return data
    }
    
    static func serialize(project: Project, compress: Bool) throws -> Data {
        let output = try project.serialize()
        let data = try JSONSerialization.data(withJSONObject: output, options: [])
        if compress {
            return try data.zip()
        }
        return data
    }
    
    
    @available(iOS 14.0, *)
    static func serialize(pkproject: PKProject, compress: Bool) throws -> Data {
        let encoder = JSONEncoder()
        let data = try encoder.encode(pkproject)
        if compress {
            return try data.zip()
        }
        return data
    }
    
    @available(iOS 13.0, *)
    static func serialize(pkdrawing: PKDrawing, compress: Bool) throws -> Data {
        let data = pkdrawing.dataRepresentation()
        if compress {
            return try data.zip()
        }
        return data
    }

    static func unserialize(data: Data) throws -> Project {
        let raw = try self.createRawData(data)
        guard let json = try JSONSerialization.jsonObject(with: raw, options: []) as? [String: Any] else {
            throw SerializerError("JSON format invalid")
        }
        return try Project(json)
    }

    private static func createRawData(_ data: Data) throws -> Data {
        if data.isZip {
            return try data.unzip(skipChecksumValidate: true)
        } else {
            return data
        }
    }

    @discardableResult
    internal static func validateVersion(_ version: Any?, _ ctx: String) throws -> PollockVersion {
        guard version != nil else {
            return PollockCurrentVersion
        }
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
