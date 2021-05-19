//
//  PKCanvas.swift
//  Pollock
//
//  Created by Erik Bye on 5/19/21.
//  Copyright © 2021 Skylar Schipper. All rights reserved.
//

import Foundation
import PencilKit

@available(iOS 14.0, *)
public final class PKCanvas : Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
            case index, drawing
        }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        drawing = try values.decode(PKDrawing.self, forKey: .drawing)
        index = try values.decode(Int.self, forKey: .index)
    }
    
    public static func == (lhs: PKCanvas, rhs: PKCanvas) -> Bool {
        if lhs.hashValue != rhs.hashValue {
            return false
        }
        return lhs === rhs

        
    }
    
    func isEmpty() -> Bool {
        return drawing.isEmpty()
    }
    
    let index: Int
    public var drawing = PKDrawing()
    
    public var hashValue: Int {
        return self.index
    }

    init(atIndex index: Int) {
        self.index = index
    }
    
    func clear() {
        drawing = PKDrawing()
    }

}
