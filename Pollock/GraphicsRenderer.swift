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
    override func draw(inContext ctx: CGContext, canvasID: Int?, forRect rect: CGRect, backgroundRenderer bg: BackgroundRenderer?) throws {
        ctx.saveGState()
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setMiterLimit(2.0)
        defer { ctx.restoreGState() }

        let canvase: Canvas = {
            if let cid = canvasID {
                return self.project.canvas(atIndex: cid)
            } else {
                return self.project.currentCanvas
            }
        }()

        for drawing in canvase.allDrawings {
            _ = try drawing.draw(inContext: ctx, withSize: rect.size, backgroundRenderer: bg)
        }
    }
}
