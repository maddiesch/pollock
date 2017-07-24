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
        let scale = ScaleFactor(toSize: rect.size, fromSize: self.project.currentCanvas.size)
        ctx.scaleBy(x: scale.x, y: scale.y)
        defer { ctx.restoreGState() }

        for drawing in self.project.currentCanvas.allDrawings {
            drawing.draw(inContext: ctx)
        }
    }
}
