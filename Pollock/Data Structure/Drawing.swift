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
    private var points: [Point] = []
    private var predictive: [Point] = []
    private let size: CGSize
    private let id: UUID
    private let smoothing: Int
    private let version: PollockVersion
    private var metadata: [String: Any] = [:]
    private var isCulled: Bool = false

    let tool: Tool

    init(size: CGSize, tool: Tool) {
        self.version = PollockCurrentVersion
        self.size = size
        self.tool = tool
        self.id = UUID()
        self.smoothing = 8
    }

    func prune() {
        self.predictive.removeAll()
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
            "smoothing": self.smoothing,
            "isCulled": self.isCulled,
            "metadata": self.metadata,
            "_type": "drawing"
        ]
    }

    init(_ payload: [String : Any]) throws {
        self.version = try Serializer.validateVersion(payload["version"], "Drawing")
        self.id = try Serializer.decodeUUID(payload["drawingID"])
        self.size = try CGSize.load(payload["size"])
        self.tool = try LoadTool(payload["tool"])
        self.smoothing = (payload["smoothing"] as? Int) ?? 8
        self.isCulled = payload["isCulled"] as? Bool ?? false
        self.metadata = payload["metadata"] as? [String: Any] ?? [:]
        guard let points = payload["points"] as? [[String: Any]] else {
            throw SerializerError("Unknown points")
        }
        self.points = try points.map { try Point($0) }
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

        let smoothed = CreateSmoothPath(fromPath: path, granularity: self.smoothing)

        ctx.addPath(smoothed)
        ctx.strokePath()
    }
}
