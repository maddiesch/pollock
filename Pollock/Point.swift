//
//  Point.swift
//  Pollock
//
//  Created by Skylar Schipper on 4/27/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

internal struct Point : Serializable {
    let location: CGPoint
    let previous: CGPoint
    let force: CGFloat
    let isPredictive: Bool

    init(location: CGPoint, previous: CGPoint, force: CGFloat, predictive: Bool) {
        self.location = location
        self.previous = previous
        self.force = force
        self.isPredictive = predictive
    }

    func draw(inContext ctx: CGContext, forDrawing drawing: Drawing) {
        ctx.move(to: self.previous)
        ctx.addLine(to: self.location)
        ctx.strokePath()
    }

    func serialize() throws -> [String : Any] {
        return [
            "previous": ["x": self.previous.x, "y": self.previous.y],
            "location": ["x": self.location.x, "y": self.location.y],
            "force": self.force,
            "isPredictive": self.isPredictive
        ]
    }
}
