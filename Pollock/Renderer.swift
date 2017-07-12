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

    @objc(serializeWithCompression:error:)
    public func serialize(compressOutput compress: Bool) throws -> Data {
        return try Serializer.serialize(context: self.context, compress: compress)
    }

    @objc(loadSerializedData:error:)
    @discardableResult
    public func load(serializedData data: Data) throws -> AnyObject {
        let context = try Serializer.unserialize(data: data)
        self.context = context
        return context
    }
}
