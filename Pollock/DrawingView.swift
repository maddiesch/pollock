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

    @objc
    public private(set) var renderer = Renderer.createRenderer()

    private var lastForce: CGFloat? = nil

    @objc
    public var currentTool: Tool = {
        let tool = PenTool()
        return tool
    }()

    @objc
    public var isSmoothingEnabled: Bool = true

    private var canvas: Canvas {
        return self.renderer.project.currentCanvas
    }

    private var isErasing: Bool {
        return self.currentTool is EraserTool
    }

    @objc
    public func clearDrawings() {
        self.canvas.clear()
        self.setNeedsDisplay()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.clear
        self.isOpaque = false

        self.layer.needsDisplayOnBoundsChange = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.backgroundColor = UIColor.clear
        self.isOpaque = false

        self.layer.needsDisplayOnBoundsChange = true
    }

    // MARK: - Touch Tracking
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let drawing = Drawing(tool: self.currentTool, isSmoothingEnabled: self.isSmoothingEnabled)
        self.currentDrawing = drawing
        self.canvas.addDrawing(drawing)
        self.process(touches, forEvent: event)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.currentDrawing?.cullExtraneous(forSize: self.bounds.size)
        self.currentDrawing = nil
        self.process(touches, forEvent: event)
        self.setNeedsDisplay()
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.currentDrawing?.cullExtraneous(forSize: self.bounds.size)
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
        if let previous = self.currentDrawing?.lastPreviousPointForPartialRender(forSize: self.bounds.size) {
            points.append(previous)
        }
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

        return CreateMinimumBoundingRect(forPoints: points, padding: self.currentTool.calculateLineWidth(forSize: self.bounds.size))
    }

    private final func handle(_ touch: UITouch, predictive: Bool) -> (CGPoint, CGPoint) {
        let rawLocation = touch.location(in: self)
        let rawPrevious = touch.previousLocation(in: self)
        var force = touch.force
        if force == 0.0 {
            force = self.lastForce ?? 1.0
        } else if predictive == false {
            self.lastForce = force
        }
        let location = Location(rawLocation, self.bounds.size)
        let previous = Location(rawPrevious, self.bounds.size)
        let point = Point(location: location, previous: previous, force: force, predictive: predictive)
        self.currentDrawing?.add(point: point)
        return (rawLocation, rawPrevious)
    }

    public override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else {
            print("Don't have a current context.  WTF!")
            return
        }
        do {
            try self.renderer.draw(inContext: ctx, forRect: self.bounds)

            // Use this to draw the render rect in orange
//            ctx.setStrokeColor(UIColor.orange.cgColor)
//            ctx.setLineWidth(1.0)
//            ctx.stroke(rect)
        } catch {
            print("Failed to draw")
            print(error)
        }
    }
}
