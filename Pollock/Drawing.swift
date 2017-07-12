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
    private let id: String
    private let smoothing: Int = 8
    private let isCulled: Bool = false

    let tool: Tool

    init(size: CGSize, tool: Tool) {
        self.size = size
        self.tool = tool
        self.id = UUID().uuidString
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
            "drawing_id": self.id,
            "version": 1,
            "tool": try self.tool.serialize(),
            "size": [self.size.width, self.size.height],
            "count": self.points.count,
            "points": try self.points.map({ try $0.serialize() }),
            "smoothing": self.smoothing,
            "isCulled": self.isCulled
        ]
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
