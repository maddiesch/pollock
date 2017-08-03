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
    private let id: UUID
    private let version: PollockVersion
    private var metadata: [String: Any] = [:]
    private var isCulled: Bool = false
    private var color: Color
    private var smoothing: Smoothing

    let size: CGSize

    let tool: Tool

    init(size: CGSize, tool: Tool) {
        self.version = PollockCurrentVersion
        self.size = size
        self.tool = tool
        self.id = UUID()
        self.smoothing = CatmullRomSmoothing()
        self.color = Color.Name.black.color
    }

    func prune() {
        self.predictive.removeAll()
    }

    func cullExtraneous() {
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
                let distance = point.location.distance(fromPoint: p1.location)
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

    func draw(inContext ctx: CGContext) {
        ctx.setLineCap(.round)
        ctx.setStrokeColor(self.color.uiColor.cgColor)
        ctx.setLineWidth(self.tool.calculateLineWidth(forForce: 1.0))
        self.drawSmoothPoints(self.points, ctx)
        for point in self.predictive {
            point.draw(inContext: ctx, forDrawing: self)
        }
    }

    func serialize() throws -> [String : Any] {
        return [
            "drawingID": self.id.uuidString,
            "version": self.version,
            "tool": try self.tool.serialize(),
            "size": try self.size.serialize(),
            "count": self.points.count,
            "points": try self.points.map({ try $0.serialize() }),
            "smoothing": try self.smoothing.serialize(),
            "isCulled": self.isCulled,
            "metadata": self.metadata,
            "color": try self.color.serialize(),
            "_type": "drawing"
        ]
    }

    init(_ payload: [String : Any]) throws {
        self.version = try Serializer.validateVersion(payload["version"], "Drawing")
        self.id = try Serializer.decodeUUID(payload["drawingID"])
        self.size = try CGSize.load(payload["size"])
        self.tool = try LoadTool(payload["tool"])
        self.smoothing = try DecodeSmoothingAlgo(payload["smoothing"])
        self.isCulled = payload["isCulled"] as? Bool ?? false
        self.metadata = payload["metadata"] as? [String: Any] ?? [:]
        guard let points = payload["points"] as? [[String: Any]] else {
            throw SerializerError("Unknown points")
        }
        self.points = try points.map { try Point($0) }
        self.color = try Color(payload["color"] as? [String: Any] ?? [:])
    }

    private func drawSmoothPoints(_ points: [Point], _ ctx: CGContext) {
        guard points.count > 0 else {
            return
        }

        let path = CGMutablePath()
        path.move(to: points[0].previous)

        for point in points {
            path.addLine(to: point.location)
        }

        let smoothed = self.smoothing.smoothPath(path)
        ctx.addPath(smoothed)
        ctx.strokePath()
    }
}

public extension Color {
    var uiColor: UIColor {
        return UIColor(red: CGFloat(self.red / 255.0), green: CGFloat(self.green / 255.0), blue: CGFloat(self.blue / 255.0), alpha: CGFloat(self.alpha))
    }
}
