//
//  DrawingView.swift
//  Pollock
//
//  Created by Skylar Schipper on 4/27/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import UIKit

@objc(POLDrawingView)
public final class DrawingView : UIView {
    internal var currentDrawing: Drawing?

    public private(set) var renderer = Renderer.createRenderer()

    private var lastForce: CGFloat? = nil

    public var currentTool: Tool = PenTool()

    private var canvas: Canvas {
        return self.renderer.project.currentCanvas
    }

    public func clearDrawings() {
        self.canvas.clear()
        self.setNeedsDisplay()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.layer.needsDisplayOnBoundsChange = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.layer.needsDisplayOnBoundsChange = true
    }

    // MARK: - Touch Tracking
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let drawing = Drawing(size: self.bounds.size, tool: self.currentTool)
        self.currentDrawing = drawing
        self.canvas.addDrawing(drawing)
        self.process(touches, forEvent: event)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.currentDrawing?.cullExtraneous()
        self.currentDrawing = nil
        self.process(touches, forEvent: event)
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.currentDrawing?.cullExtraneous()
        self.currentDrawing = nil
        self.process(touches, forEvent: event)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.process(touches, forEvent: event)
    }

    // MARK: - Touch Processing
    private final func process(_ touches: Set<UITouch>, forEvent event: UIEvent?) {
        guard let event = event else {
            return
        }
        var rect = CGRect.zero
        for touch in touches {
            rect = self.process(touch: touch, forEvent: event)
        }
        if !rect.isEmpty {
            self.setNeedsDisplay(rect)
        }
    }

    private final func process(touch: UITouch, forEvent event: UIEvent) -> CGRect {
        var touches: [UITouch] = []
        if let coalesced = event.coalescedTouches(for: touch) {
            touches = coalesced
        } else {
            touches.append(touch)
        }
        var points: [CGPoint] = []
        for touch in touches {
            let (l, p) = self.handle(touch, predictive: false)
            points.append(contentsOf: [l, p])
        }
        self.currentDrawing?.prune()
        if let predictive = event.predictedTouches(for: touch) {
            for pre in predictive {
                let (l, p) = self.handle(pre, predictive: true)
                points.append(contentsOf: [l, p])
            }
        }

        return CreateMinimumBoundingRect(forPoints: points, padding: 32.0)
    }

    private final func handle(_ touch: UITouch, predictive: Bool) -> (CGPoint, CGPoint) {
        let location = touch.location(in: self)
        let previous = touch.previousLocation(in: self)
        var force = touch.force
        if force == 0.0 {
            force = self.lastForce ?? 1.0
        } else if predictive == false {
            self.lastForce = force
        }
        let point = Point(location: location, previous: previous, force: force, predictive: predictive)
        self.currentDrawing?.add(point: point)
        return (location, previous)
    }

    public override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else {
            print("Don't have a current context.  WTF!")
            return
        }
        do {
            let start = CFAbsoluteTimeGetCurrent()
            try self.renderer.draw(inContext: ctx, forRect: self.bounds)
            let end = CFAbsoluteTimeGetCurrent()
            print("time: \((end - start) * 1000.0)")
        } catch {
            print("Failed to draw")
            print(error)
        }
    }
}
