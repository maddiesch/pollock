//
//  Point.swift
//  Pollock
//
//  Created by Skylar Schipper on 4/27/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

internal struct Point : Serializable {
    let version: PollockVersion
    let location: CGPoint
    let previous: CGPoint
    let force: CGFloat
    let isPredictive: Bool

    init(location: CGPoint, previous: CGPoint, force: CGFloat, predictive: Bool) {
        self.version = PollockCurrentVersion
        self.location = location
        self.previous = previous
        self.force = force
        self.isPredictive = predictive
    }

    func isValidMovement(fromPoint point: Point) -> Bool {
        let distance = self.location.distance(fromPoint: point.location)
        return distance >= 2.0
    }

    func draw(inContext ctx: CGContext, forDrawing drawing: Drawing) {
        ctx.move(to: self.previous)
        ctx.addLine(to: self.location)
        ctx.strokePath()
    }

    func serialize() throws -> [String : Any] {
        return [
            "version": self.version,
            "previous": try self.previous.serialize(),
            "location": try self.location.serialize(),
            "force": self.force,
            "isPredictive": self.isPredictive,
            "_type": "point"
        ]
    }

    init(_ payload: [String : Any]) throws {
        self.version = try Serializer.validateVersion(payload["version"], "Point")
        self.previous = try CGPoint.load(payload["previous"])
        self.location = try CGPoint.load(payload["location"])
        self.force = payload["force"] as? CGFloat ?? 1.0
        self.isPredictive = payload["isPredictive"] as? Bool ?? false
    }
}
