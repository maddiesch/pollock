//
//  Context.swift
//  Pollock
//
//  Created by Skylar Schipper on 5/11/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

internal final class Context {
    let id: String

    init() {
        self.id = UUID().uuidString
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
}
