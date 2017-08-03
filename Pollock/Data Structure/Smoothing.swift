//
//  Smoothing.swift
//  Pollock
//
//  Created by Skylar Schipper on 7/6/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import QuartzCore

internal protocol Smoothing : Serializable {
    var name: String { get }
    var parameters: [String: Any] { get }

    init(name: String, parameters: [String: Any]) throws

    func smoothPath(_ path: CGPath) -> CGPath
}

extension Smoothing {
    func serialize() throws -> [String : Any] {
        return [
            "name": self.name,
            "parameters": self.parameters
        ]
    }

    init(_ payload: [String : Any]) throws {
        guard let name = payload["name"] as? String else {
            throw SerializerError("Missing name for smoothing")
        }
        guard let params = payload["parameters"] as? [String: Any] else {
            throw SerializerError("Missing parameters for smoothing")
        }
        try self.init(name: name, parameters: params)
    }
}

func DecodeSmoothingAlgo(_ raw: Any?) throws -> Smoothing {
    guard let payload = raw as? [String: Any] else {
        return CatmullRomSmoothing()
    }
    guard let name = payload["name"] as? String else {
        return CatmullRomSmoothing()
    }
    switch name {
    case "catmull-rom":
        return try CatmullRomSmoothing(payload)
    default:
        return CatmullRomSmoothing()
    }
}
