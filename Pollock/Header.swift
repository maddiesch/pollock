//
//  Header.swift
//  Pollock
//
//  Created by Skylar Schipper on 7/12/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

internal struct Header : Serializable {
    let version: PollockVersion
    let id: UUID

    func serialize() throws -> [String: Any] {
        return [
            "version": self.version,
            "contextID": self.id.uuidString,
        ]
    }

    init() {
        self.version = PollockCurrentVersion
        self.id = UUID()
    }

    init(_ payload: [String: Any]) throws {
        self.version = try Serializer.validateVersion(payload["version"], "Context Header")
        self.id = try Serializer.decodeUUID(payload["contextID"])
    }
}
