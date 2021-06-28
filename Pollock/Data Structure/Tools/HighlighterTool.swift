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
        self.lineWidth = CGFloat(truncating: payload["lineWidth"] as? NSNumber ?? 1.0)
        self.forceSensitivity = CGFloat(truncating: payload["forceSensitivity"] as? NSNumber ?? 1.0)
    }

    public override var localizedUndoName: String {
        return Localized("pollock.tool.undo-name-high")
    }

    public override var localizedName: String {
        return Localized("pollock.tool.name-high")
    }

    internal override func configureContextForDrawing(_ settings: RenderSettings, _ ctx: CGContext, _ size: CGSize) throws {
        let lineWidth = self.calculateLineWidth(forSize: size)
        ctx.setLineWidth(lineWidth)

        switch settings.highlightStyle {
        case .alpha:
            ctx.setBlendMode(.normal)
            ctx.setAlpha(0.6)
        case .normal:
            ctx.setBlendMode(.multiply)
        }
    }
}
