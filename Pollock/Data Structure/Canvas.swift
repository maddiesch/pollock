//
//  Context.swift
//  Pollock
//
//  Created by Skylar Schipper on 5/11/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import PencilKit

internal final class Canvas : Serializable, Hashable {
    let index: Int

    init(atIndex index: Int) {
        self.index = index
    }

    private var drawings: [Drawing] = []

    var allDrawings: [Drawing] {
        return self.drawings
    }
    var canvasSize: CGSize = CGSize.zero {
        didSet {
            if #available(iOS 14.0, *) {
                if canvasSize != .zero, let drawing = pkdrawing {
                    _pkFullScaleDrawing = PKDrawingExtractor.upscalePoints(ofDrawing: drawing, withSize: canvasSize)
                }
            }
        }
    }
    var _pkDrawingOriginal: Any?
    var _pkdrawing: Any?
    var _pkFullScaleDrawing: Any? {
        didSet {
            if #available(iOS 14.0, *), let fullScaleDrawing = _pkFullScaleDrawing as? PKDrawing {
                _pkdrawing = PKDrawingExtractor.downscalePoints(ofDrawing: fullScaleDrawing, withSize: canvasSize)
            }
        }
    }
    @available(iOS 14.0, *)
    var pkdrawing: PKDrawing? {
        if let drawing = _pkdrawing as? PKDrawing {
            return drawing
        }
        return nil
    }

    func addDrawing(_ drawing: Drawing) {
        self.drawings.append(drawing)
    }
    
    func revertPK() {
        _pkdrawing = _pkDrawingOriginal
    }
    
    private var text: [Text] = []

    var allText: [Text] {
        return self.text
    }

    func addText(_ text: Text) {
        let existing = self.text.filter { $0.id == text.id }
        for replace in existing {
            if let index = self.text.index(where: { $0.id == replace.id}) {
                self.text.remove(at: index)
            }
        }
        self.text.append(text)
    }

    @discardableResult
    func removeTextWithID(_ id: UUID) -> Text? {
        if let index = self.text.index(where: { $0.id == id }) {
            return self.text.remove(at: index)
        }
        return nil
    }

    internal func clear() {
        _pkdrawing = nil
        _pkFullScaleDrawing = nil
        self.drawings.removeAll()
        self.text.removeAll()
        let notification = Notification(name: .canvasDidClear, object: self)
        NotificationCenter.default.post(notification)
    }

    // MARK: - Serialization
    func serialize() throws -> [String : Any] {
        return [
            "index": self.index,
            "drawings": self.drawings.compactMap { try? $0.serialize() },
            "text": self.text.compactMap { try? $0.serialize() },
            "_type": "canvas"
        ]
    }
    
    func serializePK() throws -> [String : Any] {
        var drawings: [[String : Any]] = []
        if #available(iOS 14.0, *) {
            if let drawing = pkdrawing, drawing.strokes.count > 0 {
                if let strokes = try? drawing.serialize() {
                    drawings = strokes
                }
            }
        }
        return [
            "index": self.index,
            "drawings": drawings,
            "text": self.text.compactMap { try? $0.serialize() },
            "_type": "canvas"
        ]
    }

    init(_ payload: [String : Any]) throws {
        guard let index = payload["index"] as? Int else {
            throw SerializerError("Missing index")
        }
        let drawings = payload["drawings"] as? [[String: Any]] ?? []
        
        
        if #available(iOS 14.0, *) {
            self._pkdrawing = try PKDrawing(payload)        
            self._pkDrawingOriginal = _pkdrawing
        }
        
        let text = payload["text"] as? [[String: Any]] ?? []
        self.drawings = drawings.compactMap {
            do {
                return try Drawing($0)
            } catch {
                print(error)
                return nil
            }
        }
        self.text = text.compactMap {
            do {
                return try Text($0)
            } catch {
                print(error)
                return nil
            }
        }
        self.index = index
    }

    // MARK: - Hashable
    static func ==(lhs: Canvas, rhs: Canvas) -> Bool {
        if lhs.hashValue != rhs.hashValue {
            return false
        }
        return lhs === rhs
    }

    var hashValue: Int {
        return self.index
    }

    func performOcclusionCulling() throws {
        let size = CGSize(width: 1000.0, height: 1000.0)
        var eraseRects: Array<CGRect> = []
        for drawing in self.drawings.reversed() {
            switch drawing.tool {
            case is EraserTool:
                drawing.cullExtraneous(forSize: size)
                guard let path = drawing.createPath(forSize: size) else {
                    continue
                }
                drawing.isCulled = false
                let rect = EraserTool.eraseRect(path)
                for erase in eraseRects {
                    if erase.contains(rect) {
                        drawing.isCulled = true
                        break
                    }
                }
                if !rect.isEmpty {
                    eraseRects.append(rect)
                }
            default:
                guard let path = drawing.createPath(forSize: size) else {
                    continue;
                }
                drawing.isCulled = false
                let rect = path.boundingBoxForCullingWithLineWidth(drawing.tool.calculateLineWidth(forSize: size))
                for erase in eraseRects {
                    if erase.contains(rect) {
                        drawing.isCulled = true
                        break
                    }
                }
            }
        }
        self.performTextCulling()
    }

    func performTextCulling() {
        for text in self.allText {
            if text.value.isEmpty {
                self.removeTextWithID(text.id)
            }
        }
    }

    internal func localizedNextUndoName() -> String {
        if let drawing = self.drawings.last {
            return drawing.tool.localizedUndoName
        }
        return Localized("pollock.undo-name.none")
    }

    internal func undo() throws -> String {
        let drawings = self.allDrawings
        guard drawings.count >= 1 else {
            return Localized("pollock.undo-name.none")
        }

        let drawing = drawings.last!
        let index = self.drawings.index { $0.id == drawing.id }
        if let i = index {
            self.drawings.remove(at: i)
        }

        try self.performOcclusionCulling()

        do {
            let notification = Notification(name: .canvasDidUndo, object: self, userInfo: [NSLocalizedDescriptionKey: drawing.tool.localizedUndoName])
            DispatchQueue.main.async {
                NotificationCenter.default.post(notification)
            }
        }

        return drawing.tool.localizedUndoName
    }
}

public extension Notification.Name {
    static let canvasDidUndo = Notification.Name(rawValue: "Pollock.CanvasDidUndoNotification")
    static let canvasDidClear = Notification.Name(rawValue: "Pollock.CanvasDidClearNotification")
}
