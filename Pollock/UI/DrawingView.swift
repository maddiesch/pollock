//
//  DrawingView.swift
//  Pollock
//
//  Created by Skylar Schipper on 4/27/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import UIKit

@objc(POLDrawingProvider)
public protocol DrawingProvider {
    func rendererForDrawingView(_ drawingView: DrawingView) -> Renderer
}

@available(iOS 10.0, *)
private var SelectionFeedbackInstance: UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()

public enum EditorState {
    case tool(Tool)
    case text
}

@objc(POLDrawingView)
public final class DrawingView : UIView {
    internal var currentDrawing: Drawing?

    public weak var drawingProvider: DrawingProvider?

    @objc
    public private(set) var renderer: Renderer = Renderer.createRenderer() {
        didSet {
            self.setNeedsDisplay()
        }
    }

    private var lastForce: CGFloat? = nil

    public var isEnabled: Bool = true {
        didSet {
            self.setNeedsDisplay()
            self.isHidden = !self.isEnabled
            self.isUserInteractionEnabled = self.isEnabled
        }
    }

    public var canvasID: Int? {
        didSet {
            self.setNeedsDisplay()
        }
    }

    public var state: EditorState = .tool(PenTool()) {
        didSet {
            self.updateTextState()
        }
    }

    public var color: Color = Color.Name.black.color {
        didSet {
            self.textView?.text.color = self.color
            self.textView?.textField.textColor = self.color.uiColor
        }
    }

    public var settings: RenderSettings? {
        didSet {
            self.setNeedsDisplay()
        }
    }

    @objc
    public var isSmoothingEnabled: Bool = true

    fileprivate var canvas: Canvas {
        if let canvasID = self.canvasID {
            return self.renderer.project.canvas(atIndex: canvasID)
        } else {
            return self.renderer.project.currentCanvas
        }
    }

    private var isErasing: Bool {
        switch self.state {
        case .tool(let tool):
            return tool is EraserTool
        default:
            return false
        }
    }

    private var currentTool: Tool {
        switch self.state {
        case .tool(let tool):
            return tool
        default:
            return PenTool()
        }
    }

    private var lastRenderRect: CGRect?

    private lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(textDrawingTapGestureRecognizerAction))
        self.addGestureRecognizer(gesture)
        return gesture
    }()

    private lazy var longPressGesture: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(textDrawingLongPressGestureRecognizerAction))
        gesture.minimumPressDuration = 0.1
        self.addGestureRecognizer(gesture)
        gesture.require(toFail: self.tapGesture)
        return gesture
    }()

    private func updateSelection() {
        if #available(iOS 10.0, *) {
            SelectionFeedbackInstance.selectionChanged()
        } else {
            print("Haptics not available...")
        }
    }

    public var isTextModeEnabled: Bool {
        switch self.state {
        case .text:
            return true
        default:
            return false
        }
    }

    public var defaultFontSize: CGFloat = Text.defaultFontSize

    @objc
    public func clearDrawings() {
        self.canvas.clear()
        self.setNeedsDisplay()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.finishSetupForInitialization()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.finishSetupForInitialization()
    }

    public init(_ provider: DrawingProvider) {
        super.init(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height:320.0))

        self.drawingProvider = provider
        self.renderer = provider.rendererForDrawingView(self)

        self.finishSetupForInitialization()
    }

    private func finishSetupForInitialization() {
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
        self.clipsToBounds = true

        self.layer.needsDisplayOnBoundsChange = true

        NotificationCenter.default.addObserver(self, selector: #selector(canvasDidUndoNotification), name: .canvasDidUndo, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(canvasDidClearNotification), name: .canvasDidClear, object: nil)

        self.updateTextState()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - State
    public func updateRenderer() {
        self.renderer = self.drawingProvider?.rendererForDrawingView(self) ?? Renderer.createRenderer()
    }

    private func createDrawing() -> Drawing {
        return Drawing(tool: self.currentTool.duplicate(), color: self.color, isSmoothingEnabled: self.isSmoothingEnabled)
    }

    // MARK: - Touch Tracking
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.isEnabled && !self.isTextModeEnabled else {
            return
        }
        let drawing = self.createDrawing()
        self.currentDrawing = drawing
        self.canvas.addDrawing(drawing)
        self.process(touches, forEvent: event)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.isEnabled && !self.isTextModeEnabled else {
            return
        }
        self.process(touches, forEvent: event)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.handleTouchesCompleted(touches, with: event)
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.handleTouchesCompleted(touches, with: event)
    }

    private func handleTouchesCompleted(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.isEnabled && !self.isTextModeEnabled else {
            return
        }
        self.currentDrawing = nil
        self.process(touches, forEvent: event)
        self.setNeedsDisplay()
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

        if self.isErasing {
            return self.eraseRenderRect()
        } else {
            if let predictive = event.predictedTouches(for: touch) {
                for pre in predictive {
                    let (l, p) = self.handle(pre, predictive: true)
                    points.append(contentsOf: [l, p])
                }
            }
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
            try self.renderer.draw(inContext: ctx, canvasID: self.canvasID, forRect: self.bounds, settings: self.settings, backgroundRenderer: nil)

            if self.isErasing {
                if let drawing = self.currentDrawing {
                    ctx.saveGState()
                    self.drawEraseInterface(ctx, EraserTool.eraseRect(drawing, self.bounds.size))
                    ctx.restoreGState()
                }
            }

            if let text = self.targetText {
                let rect = text.textRectForCanvasSize(self.bounds.size)
                ctx.setFillColor(UIColor(white: 0.6, alpha: 0.3).cgColor)
                ctx.fill(rect)
            }

            if let color = self.settings?.renderBoxColor {
                ctx.setStrokeColor(color)
                ctx.setLineWidth(1.0)
                ctx.stroke(rect)
            }

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

    @objc private func canvasDidUndoNotification(_ notif: Notification) {
        guard let updated = notif.object as? Canvas else {
            return
        }
        if updated == self.canvas {
            self.setNeedsDisplay()
        }
    }

    @objc private func canvasDidClearNotification(_ notif: Notification) {
        guard let updated = notif.object as? Canvas else {
            return
        }
        if updated == self.canvas {
            self.setNeedsDisplay()
        }
    }

    public override func endEditing(_ force: Bool) -> Bool {
        self.endTextEditing(false, commit: true)

        return super.endEditing(force)
    }

    // MARK: - Text Editing
    private func beginEditingText(_ text: Text) {
        self.endTextEditing(false, commit: true)
        let view = TextDrawingView(text)
        self.addSubview(view)
        do {
            self.textView = view
            try view.beginEditing()
            text.isRenderable = false
            self.setNeedsDisplay()
        } catch {
            view.removeFromSuperview()
        }
    }

    public func endTextEditing(_ animated: Bool, commit: Bool) {
        if let view = self.textView {
            try? view.endEditing()
            view.removeFromSuperview()

            view.text.isRenderable = true

            if commit && view.text.value.count > 0 {
                self.canvas.addText(view.text)
            } else {
                self.canvas.removeTextWithID(view.text.id)
            }
        }
        self.textView = nil
        self.updateTextState()
        self.setNeedsDisplay()
    }

    func updateTextState() {
        self.tapGesture.isEnabled = self.isTextModeEnabled
        self.longPressGesture.isEnabled = self.isTextModeEnabled
    }

    internal func textViewShouldEndEditing(_ textView: TextDrawingView, _ shouldDelete: Bool) {
        self.endTextEditing(true, commit: !shouldDelete)
    }

    private var textView: TextDrawingView? = nil

    private var targetText: Text? = nil {
        willSet {
            if self.targetText?.id != newValue?.id {
                self.setNeedsDisplay()
            }
        }
    }

    public weak var textDrawingToolbarViewDelegate: TextDrawingToolbarDelegate?

    private var startingPoint: CGPoint?

    @objc private func textDrawingTapGestureRecognizerAction(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: self)
        if let text = self.textForLocation(point) {
            self.beginEditingText(text)
        } else {
            let location = Location(point, self.bounds.size)
            let text = Text("", self.color, location, .arial, self.defaultFontSize)
            self.beginEditingText(text)
        }
    }

    @objc private func textDrawingLongPressGestureRecognizerAction(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            self.updateSelection()
            self.endTextEditing(false, commit: true)
            let location = sender.location(in: self)
            self.startingPoint = location
            self.targetText = self.textForLocation(location)
        case .changed:
            if let target = self.targetText, let starting = self.startingPoint {
                let current = target.location.point(forSize: self.bounds.size)
                let point = sender.location(in: self)
                let translation = point.translation(fromPoint: starting)
                let updated = current.offset(byPoint: translation)
                self.startingPoint = point
                target.location = Location(updated, self.bounds.size)
                self.setNeedsDisplay()
            }
        case .ended, .cancelled:
            self.targetText = nil
            self.startingPoint = nil
        default:
            break
        }
    }
 
    private func textForLocation(_ location: CGPoint) -> Text? {
        for text in self.canvas.allText {
            let rect = text.textRectForCanvasSize(self.bounds.size)
            guard !rect.isEmpty else {
                continue
            }
            let insetRect = UIEdgeInsetsInsetRect(rect, UIEdgeInsetsMake(-8.0, -8.0, -8.0, -8.0))
            if insetRect.contains(location) {
                return text
            }
        }
        return nil
    }

    public func currentTextFieldFrame() -> CGRect? {
        guard let text = self.textView else {
            return nil
        }
        return text.frame
    }
}

public extension DrawingView {
    public func localizedNextUndoName() -> String {
        return self.canvas.localizedNextUndoName()
    }

    public var canUndo: Bool {
        return self.canvas.canUndo
    }

    public func undo() throws -> String {
        return try self.canvas.undo()
    }
}
