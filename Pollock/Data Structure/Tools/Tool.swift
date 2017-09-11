//
//  Tool.swift
//  Pollock
//
//  Created by Skylar Schipper on 5/11/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import QuartzCore

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

    public internal(set) var version: PollockVersion = PollockCurrentVersion

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

    internal func configureContextForDrawing(_ settings: RenderSettings, _ ctx: CGContext, _ size: CGSize) throws {
        ctx.setLineWidth(self.calculateLineWidth(forSize: size))
        ctx.setBlendMode(.normal)
    }

    internal func performDrawingInContext(_ settings: RenderSettings, _ ctx: CGContext, path: CGPath, size: CGSize, drawing: Drawing, backgroundRenderer bg: BackgroundRenderer?) throws {
        ctx.addPath(path)
        ctx.strokePath()

        if let color = settings.cullingBoxColor {
            let width = self.calculateLineWidth(forSize: size)
            let rect = path.boundingBoxForCullingWithLineWidth(width)
            ctx.setLineWidth(1.0)
            ctx.addRect(rect)
            ctx.setStrokeColor(color)
            ctx.strokePath()
        }
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

public let kToolValueChangedName = "name"

public extension Notification.Name {
    static let toolValueChanged = Notification.Name(rawValue: "PollockToolChangedValueNotification")
}

protocol Duplicating {
    func duplicate() -> Self
}
