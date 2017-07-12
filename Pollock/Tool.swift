//
//  Tool.swift
//  Pollock
//
//  Created by Skylar Schipper on 5/11/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

@objc(POLTool)
open class Tool : NSObject, Serializable {
    open var lineWidth: CGFloat = 0.0

    open var forceSensitivity: CGFloat = 0.0

    open func calculateLineWidth(forForce force: CGFloat) -> CGFloat {
        assert(self.forceSensitivity > 0.0, "Can't have a force forceSensitivity of 0")
        return self.lineWidth * (force / self.forceSensitivity)
    }

    open var name: String {
        return "tool"
    }

    open fileprivate(set) var version: PollockVersion = PollockCurrentVersion

    public func serialize() throws -> [String : Any] {
        return [
            "name": self.name,
            "version": self.version,
            "lineWidth": self.lineWidth,
            "force": self.forceSensitivity
        ]
    }

    public override init() {
        super.init()
    }

    public required init(_ payload: [String : Any]) throws {
        fatalError("Can't un-serialize a generic tool")
    }
}

internal func LoadTool(_ object: Any?) throws -> Tool {
    guard let payload = object as? [String: Any] else {
        throw SerializerError("Unexpected tool type payload")
    }
    guard let name = payload["name"] as? String else {
        throw SerializerError("Missing tool name")
    }
    switch name {
    case "pen":
        return try PenTool(payload)
    default:
        throw SerializerError("Unsupported tool type \(name)")
    }
}



@objc(POLPenTool)
public final class PenTool : Tool {
    public override var name: String {
        return "pen"
    }

    public override init() {
        super.init()

        self.version = PollockCurrentVersion
        self.lineWidth = 16.0
        self.forceSensitivity = 8.0
    }
    
    public required init(_ payload: [String : Any]) throws {
        super.init()
        self.version = try Serializer.validateVersion(payload["version"], "PenTool")
        self.lineWidth = payload["lineWidth"] as? CGFloat ?? 16.0
        self.forceSensitivity = payload["force"] as? CGFloat ?? 8.0
    }
}
