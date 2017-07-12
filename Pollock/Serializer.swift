//
//  Serializer.swift
//  Pollock
//
//  Created by Skylar Schipper on 5/11/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

struct Serializer {
    private enum Keys : String {
        case header = "header"
        case drawings = "drawings"
    }

    static func serialize(context: Context, compress: Bool) throws -> Data {
        let drawings = try context.allDrawings.map { try $0.serialize() }
        let output: [String: Any] = [
            Keys.header.rawValue: self.header(context, drawings.count),
            Keys.drawings.rawValue: drawings
        ]
        let data = try JSONSerialization.data(withJSONObject: output, options: [])
        if compress {
            return try data.zip()
        }
        return data
    }

    private static func header(_ context: Context, _ drawingsCount: Int) -> [String: Any] {
        return [
            "count": drawingsCount,
            "version": 1,
            "context_id": context.id
        ]
    }
}
