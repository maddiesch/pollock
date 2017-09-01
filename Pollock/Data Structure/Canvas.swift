//
//  Context.swift
//  Pollock
//
//  Created by Skylar Schipper on 5/11/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

internal final class Canvas : Serializable, Hashable {
    let index: Int

    init(atIndex index: Int) {
        self.index = index
    }

    private var drawings: [Drawing] = []

    var allDrawings: [Drawing] {
        return self.drawings
    }

    func addDrawing(_ drawing: Drawing) {
        self.drawings.append(drawing)
    }

    func clear() {
        self.drawings.removeAll()
    }

    // MARK: - Serialization
    func serialize() throws -> [String : Any] {
        let drawings = try self.drawings.map { try $0.serialize() }
        return [
            "index": self.index,
            "drawings": drawings,
            "_type": "canvas"
        ]
    }

    init(_ payload: [String : Any]) throws {
        guard let drawings = payload["drawings"] as? [[String: Any]] else {
            throw SerializerError("Missing drawings")
        }
        guard let index = payload["index"] as? Int else {
            throw SerializerError("Missing index")
        }
        self.drawings = try drawings.map { try Drawing($0) }
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
                guard let path = drawing.createPath(forSize: size) else {
                    continue;
                }
                drawing.isCulled = false
                let rect = EraserTool.eraseRect(path)
                for erase in eraseRects {
                    if erase.contains(rect) {
                        drawing.isCulled = true
                        break;
                    }
                }
                if !rect.isEmpty {
                    eraseRects.append(rect)
                }
            case is TextTool:
                break;
            default:
                guard let path = drawing.createPath(forSize: size) else {
                    continue;
                }
                drawing.isCulled = false
                let rect = path.boundingBoxForCullingWithLineWidth(drawing.tool.calculateLineWidth(forSize: size))
                for erase in eraseRects {
                    if erase.contains(rect) {
                        drawing.isCulled = true
                        break;
                    }
                }
            }
        }
    }

    internal func localizedNextUndoName() -> String {
        if let drawing = self.drawings.last {
            return drawing.tool.localizedUndoName
        }
        return Localized("pollock.undo-name.none")
    }

    internal var canUndo: Bool {
        return self.drawings.count >= 1
    }

    internal func undo() throws -> String {
        guard self.drawings.count >= 1 else {
            return Localized("pollock.undo-name.none")
        }

        let drawing = self.drawings.removeLast()
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
}
