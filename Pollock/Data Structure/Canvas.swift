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
}
