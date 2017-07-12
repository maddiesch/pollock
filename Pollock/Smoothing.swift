//
//  Smoothing.swift
//  Pollock
//
//  Created by Skylar Schipper on 7/6/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import QuartzCore

fileprivate extension CGPath {
    func forEach(_ block: @convention(block) (CGPathElement) -> Void) {
        typealias Body = @convention(block) (CGPathElement) -> Void
        let callback: @convention(c) (UnsafeMutableRawPointer, UnsafePointer<CGPathElement>) -> Void = { info, element in
            let body = unsafeBitCast(info, to: Body.self)
            body(element.pointee)
        }
        let unsafeBody = unsafeBitCast(block, to: UnsafeMutableRawPointer.self)
        self.apply(info: unsafeBody, function: unsafeBitCast(callback, to: CGPathApplierFunction.self))
    }

    func getPoints() -> [CGPoint] {
        var points : [CGPoint]! = [CGPoint]()
        self.forEach { element in
            switch (element.type) {
            case .moveToPoint:
                points.append(element.points[0])
            case .addLineToPoint:
                points.append(element.points[0])
            case .addQuadCurveToPoint:
                points.append(element.points[0])
                points.append(element.points[1])
            case .addCurveToPoint:
                points.append(element.points[0])
                points.append(element.points[1])
                points.append(element.points[2])
            case .closeSubpath:
                break;
            }
        }
        return points
    }
}

fileprivate func AlgoMath(_ p0: CGFloat, _ p1: CGFloat, _ p2: CGFloat, _ p3: CGFloat, _ t: CGFloat, _ tt: CGFloat, _ ttt: CGFloat) -> CGFloat {
    return 0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * tt + (3.0 * p1 - p0 - 3.0 * p2 + p3) * ttt)
}

// Smooth a path using the Catmull–Rom spline algorithm
func CreateSmoothPath(fromPath path: CGPath, granularity: Int) -> CGPath {
    var points = path.getPoints()
    guard points.count > 4 else {
        guard let copy = path.copy() else {
            fatalError()
        }
        return copy
    }
    // Insert extra control points for the #math to work out
    points.insert(points[0], at: 0)
    points.append(points.last!)


    let smoothed = CGMutablePath()
    smoothed.move(to: points[0])

    // Add the first 3 points before we start to smooth
    for idx in (0..<3) {
        smoothed.addLine(to: points[idx])
    }

    let calc = (1.0 / CGFloat(granularity))

    for idx in (4..<points.count) {
        let p0 = points[idx - 3]
        let p1 = points[idx - 2]
        let p2 = points[idx - 1]
        let p3 = points[idx]

        for sub in (0..<granularity) {
            let t = CGFloat(sub) * calc
            let tt = t * t
            let ttt = tt * t

            let pi = CGPoint(
                x: AlgoMath(p0.x, p1.x, p2.x, p3.x, t, tt, ttt),
                y: AlgoMath(p0.y, p1.y, p2.y, p3.y, t, tt, ttt)
            )
            smoothed.addLine(to: pi)
        }
        smoothed.addLine(to: p2)
    }

    smoothed.addLine(to: points.last!)

    return smoothed
}
