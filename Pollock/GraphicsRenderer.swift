//
//  GraphicsRenderer.swift
//  Pollock
//
//  Created by Skylar Schipper on 5/11/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

internal class GraphicsRenderer : Renderer {

    func drawText(inContext ctx: CGContext, canvasID: Int?, forRect rect: CGRect, settings: RenderSettings?, backgroundRenderer bg: BackgroundRenderer?) throws {
        let canvas: Canvas = {
            if let cid = canvasID {
                return self.project.canvas(atIndex: cid)
            } else {
                return self.project.currentCanvas
            }
        }()

        let finalSettings = settings ?? RenderSettings.defaultSettings()
        try drawText(canvas, ctx, rect, finalSettings)
    }
    
    override func draw(inContext ctx: CGContext, canvasID: Int?, forRect rect: CGRect, settings: RenderSettings?, backgroundRenderer bg: BackgroundRenderer?) throws {
        ctx.saveGState()
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setMiterLimit(2.0)
        defer { ctx.restoreGState() }

        let canvas: Canvas = {
            if let cid = canvasID {
                return self.project.canvas(atIndex: cid)
            } else {
                return self.project.currentCanvas
            }
        }()

        let finalSettings = settings ?? RenderSettings.defaultSettings()
        try drawJSONStrokes(canvas, ctx, rect, finalSettings, bg)
        try drawText(canvas, ctx, rect, finalSettings)
    }
    
    func drawText(_ canvas: Canvas, _ ctx: CGContext, _ rect: CGRect, _ finalSettings: RenderSettings) throws {
        for text in canvas.allText {
            try text.draw(inContext: ctx, size: rect.size, settings: finalSettings)
        }
    }
    
    func drawJSONStrokes(_ canvas: Canvas, _ ctx: CGContext, _ rect: CGRect, _ finalSettings: RenderSettings, _ bg: BackgroundRenderer?) throws {
        for drawing in canvas.allDrawings {
            _ = try drawing.draw(inContext: ctx, withSize: rect.size, settings: finalSettings, backgroundRenderer: bg)
        }
    }
}
