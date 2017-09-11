//
//  EraserTool.swift
//  Pollock
//
//  Created by Skylar Schipper on 9/8/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

@objc(POLEraserTool)
public final class EraserTool : Tool {
    public override var name: String {
        return "eraser"
    }

    public override var isSmoothingSupported: Bool {
        return false
    }

    public override init() {
        super.init()

        self.version = PollockCurrentVersion
    }

    public required init(_ payload: [String : Any]) throws {
        super.init()
        self.version = try Serializer.validateVersion(payload["version"], "EraserTool")
    }

    internal override func performDrawingInContext(_ settings: RenderSettings, _ ctx: CGContext, path: CGPath, size: CGSize, drawing: Drawing, backgroundRenderer bg: BackgroundRenderer?) throws {
        let rect = EraserTool.eraseRect(path)
        if rect.isEmpty {
            return
        }
        if let background = bg {
            try background.drawBackground(inContext: ctx, withRect: rect)
        } else {
            ctx.setFillColor(settings.eraserFillColor)
            ctx.clear(rect)
        }
    }

    internal static func eraseRect(_ path: CGPath) -> CGRect {
        let points = path.getPoints()
        guard points.count >= 2 else {
            return CGRect.null
        }
        return CGRect(points.first!, points.last!)
    }

    internal static func eraseRect(_ drawing: Drawing, _ size: CGSize) -> CGRect {
        let points = drawing.allPoints
        guard points.count >= 2 else {
            return CGRect.null
        }
        let p1 = points.first!.location.point(forSize: size)
        let p2 = points.last!.location.point(forSize: size)
        return CGRect(p1, p2).integral
    }

    public override var localizedUndoName: String {
        return Localized("pollock.tool.undo-name-erase")
    }

    public override var localizedName: String {
        return Localized("pollock.tool.name-erase")
    }
}
