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
    override func draw(inContext ctx: CGContext, forRect rect: CGRect) throws {
        ctx.saveGState()
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setMiterLimit(0.0)
        defer { ctx.restoreGState() }

        var performed = 0
        var count = 0
        for drawing in self.project.currentCanvas.allDrawings {
            count += 1
            if drawing.draw(inContext: ctx, withSize: rect.size) {
                performed += 1
            }
        }
        print("RENDER: \(performed) of \(count)")
    }
}
