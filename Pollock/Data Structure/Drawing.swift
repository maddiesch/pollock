//
//  Drawing.swift
//  Pollock
//
//  Created by Skylar Schipper on 4/27/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

internal final class Drawing : Serializable {
    static let threshold: CGFloat = 2.0

    private var points: [Point] = []
    private var predictive: [Point] = []
    internal let id: UUID
    private let version: PollockVersion
    internal var color: Color
    internal var isCulled: Bool = false

    public let isSmoothingEnabled: Bool

    let tool: Tool

    internal var allPoints: [Point] {
        return self.points
    }

    init(tool: Tool, color: Color, isSmoothingEnabled: Bool = true) {
        self.version = PollockCurrentVersion
        self.tool = tool
        self.id = UUID()
        self.color = color
        self.isSmoothingEnabled = isSmoothingEnabled
    }

    func prune() {
        self.predictive.removeAll()
    }

    func cullExtraneous(forSize size: CGSize) {
        switch self.tool {
        case is EraserTool:
            self.cullErasePoints()
        default:
            self.cullPoints(size)
        }
    }

    private func cullErasePoints() {
        guard self.points.count >= 2 else {
            return
        }
        let first = self.points.first!
        let last = self.points.last!
        self.points = [
            Point(location: first.location, previous: first.location, force: 1.0, predictive: false),
            Point(location: last.location, previous: first.location, force: 1.0, predictive: false)
        ]
    }

    private func cullPoints(_ size: CGSize) {
        let count = self.points.count
        guard count >= 3 else {
            return
        }
        var culled = Array<Point>()
        culled.reserveCapacity(self.points.count)
        for (index, point) in self.points.enumerated() {
            if index == 0 || index == count - 1 {
                culled.append(point)
            } else {
                guard let p1 = culled.last else {
                    culled.append(point)
                    continue
                }
                let distance = point.location.distanceFromLocation(p1.location, withSize: size)
                if distance >= Drawing.threshold {
                    let new = Point(location: point.location, previous: p1.location, force: point.force, predictive: point.isPredictive)
                    culled.append(new)
                }
            }
        }
        #if DEBUG
            print("Pollock: Culled \(count - culled.count) points")
        #endif
        self.points = culled
    }

    func add(point: Point) {
        if point.isPredictive {
            self.predictive.append(point)
        } else {
            self.points.append(point)
        }
    }

    func lastPreviousPointForPartialRender(forSize size: CGSize) -> CGPoint? {
        guard let last = self.points.last else {
            return nil
        }
        return last.previous.point(forSize: size)
    }

    func createPath(forSize size: CGSize) -> CGPath? {
        return self.createPath(self.points, size)
    }

    func createPath(_ points: Array<Point>, _ size: CGSize) -> CGPath? {
        guard points.count > 0 else {
            return nil
        }
        let rawPoints = points.map { RawPoint(location: $0.location.point(forSize: size), previous: $0.previous.point(forSize: size)) }
        let smoothing = self.isSmoothingEnabled && self.tool.isSmoothingSupported
        return CreateQuadCurvePath(rawPoints, !smoothing)
    }

    func draw(inContext ctx: CGContext, withSize size: CGSize, settings: RenderSettings, backgroundRenderer bg: BackgroundRenderer?) throws -> Bool {
        if self.isCulled {
            return false
        }
        ctx.saveGState()
        defer { ctx.restoreGState() }
        ctx.setStrokeColor(self.color.uiColor.cgColor)
        try self.tool.configureContextForDrawing(settings, ctx, size)
        if let path = self.createPath(self.points, size) {
            try self.tool.performDrawingInContext(settings, ctx, path: path, size: size, drawing: self, backgroundRenderer: bg)
        }
        if self.tool is PenTool {
            for point in self.predictive {
                point.draw(inContext: ctx, withSize: size, forDrawing: self)
            }
        }
        
        
        //DEBUG for JSON points:
//        ctx.setFillColor(UIColor.gray.cgColor)
//        for point in points {
//            var local = point.location.point(forSize: size)
//            local.x -= 2
//            local.y -= 2
//            ctx.fillEllipse(in: CGRect(origin: local, size: CGSize(width: 4, height: 4)))
//        }
        
        return true
    }

    func serialize() throws -> [String : Any] {
        return [
            "drawingID": self.id.uuidString,
            "version": self.version,
            "tool": try self.tool.serialize(),
            "points": try self.points.map({ try $0.serialize() }),
            "isCulled": self.isCulled,
            "color": try self.color.serialize(),
            "isSmoothingEnabled": self.isSmoothingEnabled,
            "_type": "drawing"
        ]
    }

    init(_ payload: [String : Any]) throws {
        _ = try Serializer.validateVersion(payload["version"], "Drawing")
        self.version = PollockCurrentVersion
        self.id = try Serializer.decodeUUID(payload["drawingID"])
        self.tool = try LoadTool(payload["tool"])
        self.isCulled = payload["isCulled"] as? Bool ?? false
        guard let points = payload["points"] as? [[String: Any]] else {
            throw SerializerError("Unknown points")
        }
        self.points = try points.map { try Point($0) }
        self.color = try Color(payload["color"] as? [String: Any] ?? [:])
        self.isSmoothingEnabled = payload["isSmoothingEnabled"] as? Bool ?? true
    }
}

public extension Color {
    var uiColor: UIColor {
        return UIColor(red: CGFloat(self.red / 255.0), green: CGFloat(self.green / 255.0), blue: CGFloat(self.blue / 255.0), alpha: CGFloat(self.alpha))
    }
}
