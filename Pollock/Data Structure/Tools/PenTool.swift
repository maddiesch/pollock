//
//  PenTool.swift
//  Pollock
//
//  Created by Skylar Schipper on 9/8/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

@objc(POLPenTool)
public final class PenTool : Tool {
    public override var name: String {
        return "pen"
    }

    public override init() {
        super.init()

        self.version = PollockCurrentVersion
        self.lineWidth = 0.01
        self.forceSensitivity = 1.0
    }

    public required init(_ payload: [String : Any]) throws {
        super.init()
        self.version = try Serializer.validateVersion(payload["version"], "PenTool")
        self.lineWidth = CGFloat(truncating: payload["lineWidth"] as? NSNumber ?? 1.0)
        self.forceSensitivity = CGFloat(truncating: payload["forceSensitivity"] as? NSNumber ?? 1.0)
    }

    public override var localizedUndoName: String {
        return Localized("pollock.tool.undo-name-pen")
    }

    public override var localizedName: String {
        return Localized("pollock.tool.name-pen")
    }
}
