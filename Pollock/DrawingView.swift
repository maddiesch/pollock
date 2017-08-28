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

    public var isEnabled: Bool = true {
        didSet {
            self.setNeedsDisplay()
            self.isHidden = !self.isEnabled
            self.isUserInteractionEnabled = self.isEnabled
        }
    }

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

    private var lastRenderRect: CGRect?

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
        guard self.isEnabled else {
            return
        }
        let drawing = Drawing(tool: self.currentTool.duplicate(), isSmoothingEnabled: self.isSmoothingEnabled)
        self.currentDrawing = drawing
        self.canvas.addDrawing(drawing)
        self.process(touches, forEvent: event)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.isEnabled else {
            return
        }
        self.currentDrawing?.cullExtraneous(forSize: self.bounds.size)
        self.currentDrawing = nil
        self.process(touches, forEvent: event)
        self.setNeedsDisplay()
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.isEnabled else {
            return
        }
        self.currentDrawing?.cullExtraneous(forSize: self.bounds.size)
        self.currentDrawing = nil
        self.process(touches, forEvent: event)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.isEnabled else {
            return
        }
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

        if self.isErasing {
            return self.eraseRenderRect()
        }

        return CreateMinimumBoundingRect(forPoints: points, padding: self.currentTool.calculateLineWidth(forSize: self.bounds.size))
    }

    private func eraseRenderRect() -> CGRect {
        return self.bounds
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
        guard self.isEnabled else {
            return
        }
        guard let ctx = UIGraphicsGetCurrentContext() else {
            print("Don't have a current context.  WTF!")
            return
        }
        do {
            try self.renderer.draw(inContext: ctx, forRect: self.bounds)

            if self.isErasing {
                if let drawing = self.currentDrawing {
                    ctx.saveGState()
                    self.drawEraseInterface(ctx, EraserTool.eraseRect(drawing, self.bounds.size))
                    ctx.restoreGState()
                }
            }

            // Use this to draw the render rect in orange
//            ctx.setStrokeColor(UIColor.orange.cgColor)
//            ctx.setLineWidth(1.0)
//            ctx.stroke(rect)

            if !rect.equalTo(self.bounds) {
                self.lastRenderRect = rect
            } else {
                self.lastRenderRect = nil
            }
        } catch {
            print("Failed to draw")
            print(error)
        }
    }

    private func drawEraseInterface(_ ctx: CGContext, _ rect: CGRect) {
        UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0).set()
        let path = UIBezierPath(rect: rect.integral)
        path.lineWidth = 1.0
        path.stroke()

        let padding: CGFloat = 2.0
        let size: CGFloat = 15.0
        let wProgress = PercentOfRange((20.0 ... 80.0), rect.width)
        let hProgress = PercentOfRange((20.0 ... 80.0), rect.height)
        let progress = min(wProgress, hProgress)
        self.tintColor.withAlphaComponent(progress).set()

        /** Horizontal **/
        // Top Left
        UIBezierPath(rect: CGRect(x: rect.minX - padding, y: rect.minY - padding, width: size, height: (padding * 2.0))).fill()
        // Top Right
        UIBezierPath(rect: CGRect(x: rect.maxX - (size - padding), y: rect.minY - padding, width: size, height: (padding * 2.0))).fill()
        // Bottom Left
        UIBezierPath(rect: CGRect(x: rect.minX - padding, y: rect.maxY - padding, width: size, height: (padding *  2.0))).fill()
        // Bottom Right
        UIBezierPath(rect: CGRect(x: rect.maxX - (size - padding), y: rect.maxY - padding, width: size, height: (padding * 2.0))).fill()

        /** Vertical **/
        // Top Left
        UIBezierPath(rect: CGRect(x: rect.minX - padding, y: rect.minY - padding, width: (padding * 2.0), height: size)).fill()
        // Top Right
        UIBezierPath(rect: CGRect(x: rect.maxX - padding, y: rect.minY - padding, width: (padding * 2.0), height: size)).fill()
        // Bottom Left
        UIBezierPath(rect: CGRect(x: rect.minX - padding, y: rect.maxY - size, width: (padding * 2.0), height: size)).fill()
        // Bottom Right
        UIBezierPath(rect: CGRect(x: rect.maxX - padding, y: rect.maxY - size, width: (padding * 2.0), height: size)).fill()

        /** Horizontal Mid **/
        self.tintColor.withAlphaComponent(PercentOfRange((60.0 ... 120.0), rect.width)).set()
        UIBezierPath(rect: CGRect(x: rect.midX - (size / 2.0), y: rect.minY - padding, width: size, height: (padding * 2.0))).fill()
        UIBezierPath(rect: CGRect(x: rect.midX - (size / 2.0), y: rect.maxY - padding, width: size, height: (padding * 2.0))).fill()

        /** Vertical Mid **/
        self.tintColor.withAlphaComponent(PercentOfRange((60.0 ... 120.0), rect.height)).set()
        UIBezierPath(rect: CGRect(x: rect.minX - padding, y: rect.midY - (size / 2.0), width: (padding * 2.0), height: size)).fill()
        UIBezierPath(rect: CGRect(x: rect.maxX - padding, y: rect.midY - (size / 2.0), width: (padding * 2.0), height: size)).fill()
    }
}
