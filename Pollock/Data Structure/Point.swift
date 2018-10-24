//
//  Point.swift
//  Pollock
//
//  Created by Skylar Schipper on 4/27/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

internal struct Point : Serializable {
    let location: Location
    let previous: Location
    let force: CGFloat
    let isPredictive: Bool

    init(location: Location, previous: Location, force: CGFloat, predictive: Bool) {
        self.location = location
        self.previous = previous
        self.force = force
        self.isPredictive = predictive
    }

    func isValidMovement(fromPoint point: Point, withSize size: CGSize) -> Bool {
        return self.location.distanceFromLocation(point.location, withSize: size) >= 2.0
    }

    func draw(inContext ctx: CGContext, withSize size: CGSize, forDrawing drawing: Drawing) {
        let previous = self.previous.point(forSize: size)
        let location = self.location.point(forSize: size)
        ctx.move(to: previous)
        ctx.addLine(to: location)
        ctx.strokePath()
    }

    func serialize() throws -> [String : Any] {
        return [
            "previous": try self.previous.serialize(),
            "location": try self.location.serialize(),
            "force": self.force,
            "isPredictive": self.isPredictive,
            "_type": "point"
        ]
    }

    init(_ payload: [String : Any]) throws {
        self.previous = try Location.load(payload["previous"])
        self.location = try Location.load(payload["location"])
        self.force = CGFloat(payload["force"] as? Double ?? 1.0)
        self.isPredictive = payload["isPredictive"] as? Bool ?? false
    }
}
