//
//  Serializable.swift
//  Pollock
//
//  Created by Skylar Schipper on 4/27/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

public protocol Serializable {
    func serialize() throws -> [String: Any]
}
