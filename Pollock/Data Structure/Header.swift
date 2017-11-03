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
            "projectID": self.id.uuidString,
            "_type": "header"
        ]
    }

    init() {
        self.version = PollockCurrentVersion
        self.id = UUID()
    }

    init(_ payload: [String: Any]) throws {
        _ = try Serializer.validateVersion(payload["version"], "Context Header")
        self.version = PollockCurrentVersion
        self.id = try Serializer.decodeUUID(payload["projectID"])
    }
}
