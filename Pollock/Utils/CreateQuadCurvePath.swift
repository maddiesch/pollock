//
//  CreateQuadCurvePath.swift
//  Pollock
//
//  Created by Skylar Schipper on 8/22/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

internal typealias RawPoint = (location: CGPoint, previous: CGPoint)

internal func CreateQuadCurvePath(_ points: Array<RawPoint>, _ override: Bool) -> CGPath {
    assert(points.count != 0, "Can't create a path without any points")

    let path = CGMutablePath()
    path.move(to: points[0].previous)

    if points.count < 4 || override {
        for point in points {
            path.addLine(to: point.location)
        }
    } else {
        for idx in (2..<points.count) {
            let p0 = points[idx - 1].location
            let p1 = points[idx].location

            let mid = Midpoint(p0, p1)
            path.addQuadCurve(to: mid, control: p0)
        }
    }
    return path
}

fileprivate func Midpoint(_ p0: CGPoint, _ p1: CGPoint) -> CGPoint {
    return CGPoint(
        x: (p0.x + p1.x) / 2.0,
        y: (p0.y + p1.y) / 2.0
    )
}
