//
//  PKGraphicsRenderer.swift
//  Pollock
//
//  Created by Erik Bye on 8/10/21.
//  Copyright © 2021 Skylar Schipper. All rights reserved.
//

import Foundation
import QuartzCore
import UIKit

internal class PKGraphicsRenderer : GraphicsRenderer {
    
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
        if #available(iOS 14.0, *) {
            if let pkDrawing = canvas.pkdrawing {
                let upscaledProject = PKDrawingExtractor.upscalePoints(ofDrawing: pkDrawing, withSize: rect.size)
                let image = upscaledProject.image(from: rect, scale: 1)
                image.draw(in: rect)
                try drawText(canvas, ctx, rect, finalSettings)
            }
        } else {
            try drawJSONStrokes(canvas, ctx, rect, finalSettings, bg)
            try drawText(canvas, ctx, rect, finalSettings)
        }   
    }
}
