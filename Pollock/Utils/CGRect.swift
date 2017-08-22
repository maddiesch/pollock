//
//  CGRect.swift
//  Pollock
//
//  Created by Skylar Schipper on 8/22/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import QuartzCore

extension CGRect {
    init(_ point1: CGPoint, _ point2: CGPoint) {
        self.init(x: min(point1.x, point2.x), y: min(point1.y, point2.y), width: abs(point1.x - point2.x), height: abs(point1.y - point2.y))
    }
}
