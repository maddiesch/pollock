//
//  Renderer.swift
//  Pollock
//
//  Created by Skylar Schipper on 5/11/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import QuartzCore

internal func CreateRenderer() -> Renderer {
    return GraphicsRenderer()
}

@objc(POLRenderer)
public class Renderer : NSObject {
    var context: Context = Context()

    func draw(inContext ctx: CGContext, forRect rect: CGRect) throws {
        fatalError("Must Override")
    }
}
