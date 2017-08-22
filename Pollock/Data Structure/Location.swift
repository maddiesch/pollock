//
//  Location.swift
//  Pollock
//
//  Created by Skylar Schipper on 8/22/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

internal struct Location : Serializable {
    let xOffset: CGFloat
    let yOffset: CGFloat

    init(_ point: CGPoint, _ size: CGSize) {
        self.xOffset = point.x / size.width
        self.yOffset = point.y / size.height
    }

    init(_ payload: [String : Any]) throws {
        guard let xOffset = payload["xOffset"] as? CGFloat else {
            throw SerializerError("Missing xOffset for Location")
        }
        guard let yOffset = payload["yOffset"] as? CGFloat else {
            throw SerializerError("Missing yOffset for Location")
        }
        self.xOffset = xOffset
        self.yOffset = yOffset
    }

    func serialize() throws -> [String : Any] {
        return [
            "xOffset": self.xOffset,
            "yOffset": self.yOffset
        ]
    }

    func point(forSize size: CGSize) -> CGPoint {
        return CGPoint(x: self.xOffset * size.width, y: self.yOffset * size.height)
    }

    func distanceFromLocation(_ location: Location, withSize size: CGSize) -> CGFloat {
        let point1 = self.point(forSize: size)
        let point2 = location.point(forSize: size)
        return point1.distance(fromPoint: point2)
    }
}
