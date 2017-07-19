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
    var project = Project()

    var currentCanvas: Canvas {
        get {
            return self.project.currentCanvas
        }
    }

    func draw(inContext ctx: CGContext, forRect rect: CGRect) throws {
        fatalError("Must Override")
    }

    @objc(serializeWithCompression:error:)
    public func serialize(compressOutput compress: Bool) throws -> Data {
        return try Serializer.serialize(project: self.project, compress: compress)
    }

    @objc(loadSerializedData:error:)
    @discardableResult
    public func load(serializedData data: Data) throws -> AnyObject {
        let project = try Serializer.unserialize(data: data)
        self.project = project
        return project
    }
}
