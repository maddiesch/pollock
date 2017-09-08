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

protocol Duplicating {
    func duplicate() -> Self
}

@objc(POLTool)
public class Tool : NSObject, Serializable, Duplicating {
    @objc
    public var lineWidth: CGFloat {
        get {
            return self._lineWidth
        }
        set {
            self._lineWidth = newValue.clamp(0.0 ... 1.0)
            self.toolValuesChanged("lineWidth")
        }
    }
    private var _lineWidth: CGFloat = 0.02

    public var forceSensitivity: CGFloat = 1.0 {
        didSet {
            self.toolValuesChanged("forceSensitivity")
        }
    }

    public func calculateLineWidth(forSize size: CGSize) -> CGFloat {
        return max(1.0, size.height * self.lineWidth);
    }

    @objc
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

    public func configureContextForDrawing(_ ctx: CGContext, _ size: CGSize) throws {
        ctx.setLineWidth(self.calculateLineWidth(forSize: size))
        ctx.setBlendMode(.normal)
    }

    public func performDrawingInContext(_ ctx: CGContext, path: CGPath, backgroundRenderer bg: BackgroundRenderer?) throws {
        ctx.addPath(path)
        ctx.strokePath()

        // This code will draw the culling box as a red stroke around the value
//        let rect = path.boundingBoxForCullingWithLineWidth(self.lineWidth)
//        ctx.setLineWidth(1.0)
//        ctx.addRect(rect)
//        ctx.setStrokeColor(UIColor.red.cgColor)
//        ctx.strokePath()
    }

    public func duplicate() -> Self {
        do {
            let dup = try self.serialize()
            return try type(of: self).init(dup)
        } catch {
            return self
        }
    }

    public var localizedUndoName: String {
        fatalError("Must override")
    }

    public var localizedName: String {
        fatalError("Must override")
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
        self.lineWidth = 0.01
        self.forceSensitivity = 1.0
    }
    
    public required init(_ payload: [String : Any]) throws {
        super.init()
        self.version = try Serializer.validateVersion(payload["version"], "PenTool")
        self.lineWidth = payload["lineWidth"] as? CGFloat ?? 16.0
        self.forceSensitivity = payload["forceSensitivity"] as? CGFloat ?? 8.0
    }

    public override var localizedUndoName: String {
        return Localized("pollock.tool.undo-name-pen")
    }

    public override var localizedName: String {
        return Localized("pollock.tool.name-pen")
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
        self.lineWidth = 0.01
        self.forceSensitivity = 1.0
    }

    public required init(_ payload: [String : Any]) throws {
        super.init()
        self.version = try Serializer.validateVersion(payload["version"], "HighlighterTool")
        self.lineWidth = payload["lineWidth"] as? CGFloat ?? 16.0
        self.forceSensitivity = payload["forceSensitivity"] as? CGFloat ?? 1.0
    }

    public override var localizedUndoName: String {
        return Localized("pollock.tool.undo-name-high")
    }

    public override var localizedName: String {
        return Localized("pollock.tool.name-high")
    }

    public override func configureContextForDrawing(_ ctx: CGContext, _ size: CGSize) throws {
        ctx.setLineWidth(self.calculateLineWidth(forSize: size))
        ctx.setBlendMode(.multiply)
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

    public override func performDrawingInContext(_ ctx: CGContext, path: CGPath, backgroundRenderer bg: BackgroundRenderer?) throws {
        let rect = EraserTool.eraseRect(path)
        if rect.isEmpty {
            return
        }
        if let background = bg {
            try background.drawBackground(inContext: ctx, withRect: rect)
        } else {
            ctx.setFillColor(UIColor.clear.cgColor)
            ctx.clear(rect)
        }
    }

    internal static func eraseRect(_ path: CGPath) -> CGRect {
        let points = path.getPoints()
        guard points.count >= 2 else {
            return CGRect.null
        }
        return CGRect(points.first!, points.last!)
    }

    internal static func eraseRect(_ drawing: Drawing, _ size: CGSize) -> CGRect {
        let points = drawing.allPoints
        guard points.count >= 2 else {
            return CGRect.null
        }
        let p1 = points.first!.location.point(forSize: size)
        let p2 = points.last!.location.point(forSize: size)
        return CGRect(p1, p2).integral
    }

    public override var localizedUndoName: String {
        return Localized("pollock.tool.undo-name-erase")
    }

    public override var localizedName: String {
        return Localized("pollock.tool.name-erase")
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

    public override var localizedUndoName: String {
        return Localized("pollock.tool.undo-name-text")
    }

    public override var localizedName: String {
        return Localized("pollock.tool.name-text")
    }
}

public let kToolValueChangedName = "name"

public extension Notification.Name {
    static let toolValueChanged = Notification.Name(rawValue: "PollockToolChangedValueNotification")
}
