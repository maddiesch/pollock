//
//  Tool.swift
//  Pollock
//
//  Created by Skylar Schipper on 5/11/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

@objc(POLTool)
public class Tool : NSObject, Serializable {
    public var lineWidth: CGFloat = 8.0 {
        didSet {
            self.toolValuesChanged("lineWidth")
        }
    }

    public var forceSensitivity: CGFloat = 1.0 {
        didSet {
            self.toolValuesChanged("forceSensitivity")
        }
    }

    public func calculateLineWidth(forForce force: CGFloat) -> CGFloat {
        assert(self.forceSensitivity > 0.0, "Can't have a force forceSensitivity of 0")
        return self.lineWidth * (force / self.forceSensitivity)
    }

    public var name: String {
        return "tool"
    }

    public fileprivate(set) var version: PollockVersion = PollockCurrentVersion

    public var isSmoothingSupported: Bool {
        return true
    }

    public func serialize() throws -> [String : Any] {
        return [
            "name": self.name,
            "version": self.version,
            "lineWidth": self.lineWidth,
            "forceSensitivity": self.forceSensitivity,
            "_type": "tool"
        ]
    }

    public override init() {
        super.init()
    }

    public required init(_ payload: [String : Any]) throws {
        fatalError("Can't un-serialize a generic tool")
    }

    public func toolValuesChanged(_ value: String) {
        let info = [kToolValueChangedName: value]
        let notification = Notification(name: .toolValueChanged, object: self, userInfo: info)
        DispatchQueue.main.async {
            NotificationCenter.default.post(notification)
        }
    }

    public func configureContextForDrawing(_ ctx: CGContext) {
        ctx.setLineWidth(self.calculateLineWidth(forForce: 1.0))
        ctx.setBlendMode(.normal)
    }

    public func performDrawingInContext(_ ctx: CGContext, path: CGPath) {
        ctx.addPath(path)
        ctx.strokePath()
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
    case "eraser":
        return try EraserTool(payload)
    case "text":
        return try TextTool(payload)
    case "highlighter":
        return try HighlighterTool(payload)
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
        self.forceSensitivity = 1.0
    }
    
    public required init(_ payload: [String : Any]) throws {
        super.init()
        self.version = try Serializer.validateVersion(payload["version"], "PenTool")
        self.lineWidth = payload["lineWidth"] as? CGFloat ?? 16.0
        self.forceSensitivity = payload["forceSensitivity"] as? CGFloat ?? 8.0
    }
}

@objc(POLHighlighterTool)
public final class HighlighterTool : Tool {
    public override var name: String {
        return "highlighter"
    }

    public override init() {
        super.init()

        self.version = PollockCurrentVersion
        self.lineWidth = 16.0
        self.forceSensitivity = 1.0
    }

    public required init(_ payload: [String : Any]) throws {
        super.init()
        self.version = try Serializer.validateVersion(payload["version"], "HighlighterTool")
        self.lineWidth = payload["lineWidth"] as? CGFloat ?? 16.0
        self.forceSensitivity = payload["forceSensitivity"] as? CGFloat ?? 1.0
    }
}

@objc(POLEraserTool)
public final class EraserTool : Tool {
    public override var name: String {
        return "eraser"
    }

    public override var isSmoothingSupported: Bool {
        return false
    }

    public override init() {
        super.init()

        self.version = PollockCurrentVersion
    }

    public required init(_ payload: [String : Any]) throws {
        super.init()
        self.version = try Serializer.validateVersion(payload["version"], "EraserTool")
    }

    public override func performDrawingInContext(_ ctx: CGContext, path: CGPath) {
        let rect = EraserTool.eraseRect(path)
        if rect.isEmpty {
            return
        }
        ctx.setFillColor(UIColor.clear.cgColor)
        ctx.clear(rect)
    }

    internal static func eraseRect(_ path: CGPath) -> CGRect {
        let points = path.getPoints()
        guard points.count >= 2 else {
            return CGRect.null
        }
        return CGRect(points.first!, points.last!)
    }
}

@objc(POLTextTool)
public final class TextTool : Tool {
    public override var name: String {
        return "text"
    }

    public override var isSmoothingSupported: Bool {
        return false
    }

    public override init() {
        super.init()

        self.version = PollockCurrentVersion
    }

    public required init(_ payload: [String : Any]) throws {
        super.init()
        self.version = try Serializer.validateVersion(payload["version"], "TextTool")
    }
}

public let kToolValueChangedName = "name"

public extension Notification.Name {
    static let toolValueChanged = Notification.Name(rawValue: "PollockToolChangedValueNotification")
}
