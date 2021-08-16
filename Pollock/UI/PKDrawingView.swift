//
//  PKDrawingView.swift
//  Pollock
//
//  Created by Erik Bye on 6/9/21.
//  Copyright © 2021 Skylar Schipper. All rights reserved.
//

import Foundation
import PencilKit

@available(iOS 10.0, *)
private var SelectionFeedbackInstance: UISelectionFeedbackGenerator = UISelectionFeedbackGenerator()


public protocol DrawingViewInterface {
    var isEnabled: Bool { get set }
    var isUserInteractionEnabled: Bool { get set }
    var canvasID: Int? { get set }
    var state: EditorState { get set }
    var color: Color { get set }
    var defaultFontSize: CGFloat { get set }
    func updateRenderer()
    func endEditing(_ force: Bool) -> Bool
    func currentTextFieldFrame() -> CGRect?
    func showToolPicker()
    func hideToolPicker()
    func undo() -> String
}

public final class PKDrawingView: UIView, PKCanvasViewDelegate, TextDrawingViewDelegate, DrawingViewInterface {
    
    public func undo() -> String {
        undoManager?.undo()
        return "Undo Text Needed"
    }
    func textDrawingToolbarDelegate() -> TextDrawingToolbarDelegate {
        return self.textDrawingToolbarViewDelegate!
    }
    
    internal var currentDrawing: Drawing?
    
    public weak var drawingProvider: DrawingProvider?
    
    @objc
    public private(set) var renderer: Renderer = Renderer.createRenderer() {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.isOpaque = false
    }
    
    public override var bounds: CGRect {
        didSet {
            self.update(canvasSize: bounds.size)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateRenderer() {
        guard let provider = self.drawingProvider else {
            return
        }
        if let renderer = provider.rendererForDrawingView() {
            self.renderer = renderer
            if PKDrawingHelper.isPencilKitAvailable {
                if #available(iOS 14.0, *) {
                    self.update(canvasSize: self.canvasView.bounds.size)
                }
            }
        }
        
        
    }
    
    public func update(canvasSize: CGSize) {
        if PKDrawingHelper.isPencilKitAvailable {
            if canvasSize != .zero {
                renderer.project.updateCanvas(withSize: canvasSize)
                updateCanvasView()
            } else {
                print("ERROR updating canvas size!")
            }
        }
    }
    
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
    
    fileprivate var canvas: Canvas {
        if let canvasID = self.canvasID {
            return self.renderer.project.canvas(atIndex: canvasID)
        } else {
            return self.renderer.project.currentCanvas
        }
    }
    
    func updateCanvasView() {
        if #available(iOS 14.0, *) {
            if let drawing = canvas.pkdrawing {
                let upscaleDrawing = PKDrawingExtractor.upscalePoints(ofDrawing: drawing, withSize: canvas.canvasSize)
                canvasView.drawing = upscaleDrawing
            }
        }
    }
    
    @available(iOS 14.0, *)
    lazy var canvasView: PKCanvasView = {
        let view = PKCanvasView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.delegate = self
        self.addSubview(view)
        self.addConstraint(NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: view, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: view, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0))
        self.toolPicker.addObserver(view)
        self.toolPicker.addObserver(self)
        self.toolPicker.setVisible(true, forFirstResponder: view)
        return view
    }()
    
    @available(iOS 14.0, *)
    private lazy var toolPicker: PKToolPicker = {
        let picker = PKToolPicker()
        return picker
    }()
    
    public func showToolPicker() {
        if #available(iOS 14.0, *) {
            self.canvasView.becomeFirstResponder()
            self.toolPicker.setVisible(true, forFirstResponder: self.canvasView)
        }
    }
    
    public func hideToolPicker() {
        if #available(iOS 14.0, *) {
            self.toolPicker.setVisible(false, forFirstResponder: self.canvasView)
        }
    }
    
    @available(iOS 13.0, *)
    public func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        if #available(iOS 14.0, *) {
            let downscaledDrawing = PKDrawingExtractor.downscalePoints(ofDrawing: self.canvasView.drawing, withSize: canvas.canvasSize)
            canvas._pkdrawing = downscaledDrawing
        }
        self.setNeedsDisplay()  //this runs draw(rect) for text
    }
    
    public override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else {
            print("Don't have a current context.  WTF!")
            return
        }
        do {
            super.draw(rect)
            if let graphicsRenderer = self.renderer as? GraphicsRenderer {
                try graphicsRenderer.drawText(inContext: ctx, canvasID: canvasID, forRect: rect, settings: nil, backgroundRenderer: nil)
            }
        } catch {
            print("Failed to draw")
            print(error)
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
        view.delgate = self
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
                canvas.addText(view.text)
            } else {
                canvas.removeTextWithID(view.text.id)
            }
        }
        self.textView = nil
        self.updateTextState()
        self.setNeedsDisplay()
    }
    
    func updateTextState() {
        guard !isHidden else {
            return
        }
        self.tapGesture.isEnabled = self.isTextModeEnabled
        self.longPressGesture.isEnabled = self.isTextModeEnabled
        if isTextModeEnabled {
            if #available(iOS 14.0, *) {
                self.hideToolPicker()
            }
        } else {
            if #available(iOS 14.0, *) {
                self.showToolPicker()
            }
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
    
    public var state: EditorState = .tool(PenTool()) {
        didSet {
            self.updateTextState()
        }
    }
    
    public var defaultFontSize: CGFloat = Text.defaultFontSize
    
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(textDrawingTapGestureRecognizerAction))
        self.addGestureRecognizer(gesture)
        return gesture
    }()
    
    private lazy var longPressGesture: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(textDrawingLongPressGestureRecognizerAction))
        gesture.minimumPressDuration = 0.35
        self.addGestureRecognizer(gesture)
        return gesture
    }()
    
    
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
            self.createAndEditTextAtPoint(point)
        }
    }
    
    private func updateSelection() {
        if #available(iOS 10.0, *) {
            SelectionFeedbackInstance.selectionChanged()
        } else {
            print("Haptics not available...")
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
            if self.targetText == nil {
                let point = sender.location(in: self)
                self.createAndEditTextAtPoint(point)
            } else {
                self.targetText = nil
                self.startingPoint = nil
            }
        default:
            break
        }
    }
    
    private func createAndEditTextAtPoint(_ point: CGPoint) {
        let location = Location(point, self.bounds.size)
        let text = Text("", self.color, location, .arial, self.defaultFontSize)
        self.beginEditingText(text)
    }
    
    private func textForLocation(_ location: CGPoint) -> Text? {
        for text in canvas.allText {
            let rect = text.textRectForCanvasSize(self.bounds.size)
            guard !rect.isEmpty else {
                continue
            }
            let insetRect = rect.inset(by: UIEdgeInsets.init(top: -8.0, left: -8.0, bottom: -8.0, right: -8.0))
            if insetRect.contains(location) {
                return text
            }
        }
        return nil
    }
    
    public func currentTextFieldFrame() -> CGRect? {
        guard let text = self.textView, !isHidden else {
            return nil
        }
        return text.frame
    }
    
    public var color: Color = Color.Name.black.color {
        didSet {
            self.textView?.text.color = self.color
            self.textView?.textColor = self.color.uiColor
        }
    }
    
    
}

@available(iOS 13.0, *)
extension PKDrawingView: PKToolPickerObserver {
    fileprivate func replaceBitmapEraserWithVector(_ toolPicker: PKToolPicker) {
        if var tool = toolPicker.selectedTool as? PKEraserTool {
            if tool.eraserType == .bitmap {
                //display an alert and switch back to vector
                NotificationCenter.default.post(Notification(name: Notification.Name("pk.pixel.eraser.disabled")))
                tool.eraserType = .vector
                if #available(iOS 14.0, *) {
                    toolPicker.selectedTool = tool
                } else {
                    toolPicker.selectedTool = tool
                }
            }
        }
    }
    
    public func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {
        replaceBitmapEraserWithVector(toolPicker)
    }
}


