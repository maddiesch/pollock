//
//  HighlighterTool.swift
//  Pollock
//
//  Created by Skylar Schipper on 9/8/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

@objc(POLHighlighterTool)
public final class HighlighterTool : Tool {
    public override var name: String {
        return "highlighter"
    }

    public override init() {
        super.init()

        self.version = PollockCurrentVersion
        self.lineWidth = 0.01
        self.forceSensitivity = 1.0
    }

    public required init(_ payload: [String : Any]) throws {
        super.init()
        self.version = try Serializer.validateVersion(payload["version"], "HighlighterTool")
        self.lineWidth = payload["lineWidth"] as? CGFloat ?? 16.0
        self.forceSensitivity = payload["forceSensitivity"] as? CGFloat ?? 1.0
    }

    public override var localizedUndoName: String {
        return Localized("pollock.tool.undo-name-high")
    }

    public override var localizedName: String {
        return Localized("pollock.tool.name-high")
    }

    internal override func configureContextForDrawing(_ settings: RenderSettings, _ ctx: CGContext, _ size: CGSize) throws {
        ctx.setLineWidth(self.calculateLineWidth(forSize: size))

        switch settings.highlightStyle {
        case .alpha:
            ctx.setBlendMode(.normal)
            ctx.setAlpha(0.6)
        case .normal:
            ctx.setBlendMode(.multiply)
        }
    }
}
