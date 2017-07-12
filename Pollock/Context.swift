//
//  Context.swift
//  Pollock
//
//  Created by Skylar Schipper on 5/11/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

internal final class Context : NSObject {
    let header: Header

    override init() {
        self.header = Header()
        super.init()
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
        let header = try self.header.serialize()
        let drawings = try self.drawings.map { try $0.serialize() }
        return [
            "header": header,
            "drawings": drawings
        ]
    }

    init(_ payload: [String : Any]) throws {
        self.header = try Header.load(payload["header"])
        guard let drawings = payload["drawings"] as? [[String: Any]] else {
            throw SerializerError("Missing drawings")
        }
        self.drawings = try drawings.map { try Drawing($0) }
    }
}
