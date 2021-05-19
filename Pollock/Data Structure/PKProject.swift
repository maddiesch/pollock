//
//  PKDrawingProject.swift
//  Pollock
//
//  Created by Erik Bye on 5/19/21.
//  Copyright © 2021 Skylar Schipper. All rights reserved.
//

import Foundation
import PencilKit


@available(iOS 14.0, *)
public final class PKProject : NSObject, Codable {
    
    
    public init?(coder: NSCoder) {
        if let drawings = coder.decodeObject(forKey: "drawings") as? Set<PKCanvas> {
            self.drawings = drawings
        }
    }
    
    private enum CodingKeys: String, CodingKey {
            case drawings
        }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        drawings = try values.decode(Set<PKCanvas>.self, forKey: .drawings)
    }

    
    
    
    init(data: Data) {
        let decoder = JSONDecoder()
        if let pkproject = try? decoder.decode(PKProject.self, from: data) {
            self.drawings = pkproject.drawings
        } else {
            print("PKProject from data didn't work")
        }
    }
    
    override public init() {
        
    }

    private var drawings: Set<PKCanvas> = []

    
    fileprivate var _currentDrawing: PKCanvas?
    var currentDrawing: PKCanvas {
        get {
            if let drawing = self._currentDrawing {
                return drawing
            }
            if let drawing = self.drawings.first {
                self._currentDrawing = drawing
                return drawing
            }
            let drawing = PKCanvas(atIndex: 0)
            self.drawings.insert(drawing)
            self._currentDrawing = drawing
            return drawing
        }
    }

    public var isEmpty: Bool {
        var empty = true
        for drawing in self.drawings {
            if !drawing.isEmpty() {
                empty = false
            }
        }
        return empty
    }
}

@available(iOS 14.0, *)
extension PKProject {
    func addCanvas(_ canvas: PKCanvas) throws {
        if self.hasCanvas(withIndex: canvas.index) {
            throw ProjectError(.existingCanvas, "There is already at canvas with index \(canvas.index)")
        }
        self.drawings.insert(canvas)
    }

    public func setActiveCanvas(withIndex index: Int) throws {
        if let canvas = self.canvas(withIndex: index) {
            self._currentDrawing = canvas
        } else {
            let canvas = PKCanvas(atIndex: index)
            try self.addCanvas(canvas)
            self._currentDrawing = canvas
        }
    }

    func hasCanvas(withIndex index: Int) -> Bool {
        return self.canvas(withIndex: index) != nil
    }
    
    public func canvas(atIndex at: Int) -> PKCanvas {
        if let canvas = self.canvas(withIndex: at) {
            return canvas
        }
        let canvas = PKCanvas(atIndex: at)
        try? self.addCanvas(canvas)
        return canvas
    }
//
    public func canvas(withIndex index: Int) -> PKCanvas? {
        for canvas in self.drawings {
            if canvas.index == index {
                return canvas
            }
        }
        return nil
    }

    func removeCanvas(withIndex index: Int) -> PKCanvas? {
        guard let canvas = self.canvas(withIndex: index) else {
            return nil
        }
        self.drawings.remove(canvas)
        return canvas
    }

    public func clearCanvas(withIndex index: Int) throws {
        self.canvas(withIndex: index)?.clear()
    }

    public func clearAllDrawings() throws {
        self.drawings.forEach { $0.clear() }
    }
}

