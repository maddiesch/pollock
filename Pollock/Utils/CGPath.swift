//
//  CGPath.swift
//  Pollock
//
//  Created by Skylar Schipper on 8/3/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import CoreGraphics

internal extension CGPath {
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

    func boundingBoxForCullingWithLineWidth(_ width: CGFloat) -> CGRect {
        let offset = ceil(width / 2.0) + 2.0
        return self.boundingBox.insetBy(dx: -offset, dy: -offset)
    }
}
