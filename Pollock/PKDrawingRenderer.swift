//
//  PKDrawingRenderer.swift
//  Pollock
//
//  Created by Erik Bye on 5/12/21.
//  Copyright © 2021 Skylar Schipper. All rights reserved.
//

import Foundation
import PencilKit

@objc(POLPKDrawingRenderer)
@available(iOS 14.0, *)
public class PKDrawingRenderer : Renderer {
    public override class func createRenderer() -> Renderer {
        return PKDrawingRenderer(1)
    }
    
    public var pkproject: PKProject = PKProject()
    
    public override func draw(inContext ctx: CGContext, canvasID: Int?, forRect rect: CGRect, settings: RenderSettings?, backgroundRenderer bg: BackgroundRenderer?) throws {
        
        let canvas: PKCanvas = {
            if let cid = canvasID {
                return self.pkproject.canvas(atIndex: cid)
            } else {
                return self.pkproject.currentDrawing
            }
        }()
        canvas.drawing.image(from: rect, scale: 1).draw(in: rect)
    }
    
    public func draw(inContext ctx: CGContext, canvasID: Int?, pageRect: CGRect, forRect rect: CGRect, settings: RenderSettings?, backgroundRenderer bg: BackgroundRenderer?) throws {
        let canvas: PKCanvas = {
            if let cid = canvasID {
                return self.pkproject.canvas(atIndex: cid)
            } else {
                return self.pkproject.currentDrawing
            }
        }()
        canvas.drawing.image(from: rect, scale: 1).draw(in: rect)
    }
    
    public override func load(serializedData data: Data) throws -> AnyObject {
        do {
            var unzipped = data
            if data.isZip {
                unzipped = try data.unzip()
            }
            pkproject = PKProject(data: unzipped )
        } catch {
            print("Failed to load PKDrawing form file")
        }
        return self
    }
    public override func serialize(compressOutput compress: Bool) throws -> Data {
        let data = try Serializer.serialize(pkproject: pkproject, compress: compress)
        return data
    }
}

@available(iOS 14.0, *)
extension PKDrawing {
    public func isEmpty() -> Bool {
        return self.strokes.isEmpty
    }
}
