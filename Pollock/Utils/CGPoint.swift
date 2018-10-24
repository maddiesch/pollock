//
//  CGPoint.swift
//  Pollock
//
//  Created by Skylar Schipper on 8/3/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import CoreGraphics

internal extension CGPoint {
    func distance(fromPoint point: CGPoint) -> CGFloat {
        return sqrt(pow((point.x - self.x), 2.0) + pow(point.y - self.y, 2.0))
    }

    func translation(fromPoint point: CGPoint) -> CGPoint {
        return CGPoint(x: self.x - point.x, y: self.y - point.y)
    }

    func offset(byPoint point: CGPoint) -> CGPoint {
        return CGPoint(x: self.x + point.x, y: self.y + point.y)
    }
}

extension CGPoint : Serializable {
    public init(_ payload: [String : Any]) throws {
        guard let x = payload["x"] as? Double else {
            throw SerializerError("Size missing width")
        }
        guard let y = payload["y"] as? Double else {
            throw SerializerError("Size missing height")
        }
        self.init(x: CGFloat(x), y: CGFloat(y))
    }

    public func serialize() throws -> [String : Any] {
        return ["x": self.x, "y": self.y]
    }
}
