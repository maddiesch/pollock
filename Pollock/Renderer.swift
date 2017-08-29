//
//  Renderer.swift
//  Pollock
//
//  Created by Skylar Schipper on 5/11/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import QuartzCore

@objc(POLRenderer)
public class Renderer : NSObject {
    public class func createRenderer() -> Renderer {
        return GraphicsRenderer(1)
    }

    public var project = Project()

    public override init() {
        fatalError("Use Renderer.createRenderer()")
    }

    internal init(_ val: Int) {
        super.init()
    }

    var currentCanvas: Canvas {
        get {
            return self.project.currentCanvas
        }
    }

    public func draw(inContext ctx: CGContext, forRect rect: CGRect) throws {
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

    @objc(loadProject:error:)
    public func load(project: AnyObject) throws {
        guard let proj = project as? Project else {
            throw ProjectError(.invalidProject, "Passed non-project object")
        }
        self.project = proj
    }

    @objc(performOcclusionCullingWithError:)
    public func performOcclusionCulling() throws {
        try self.project.performOcclusionCulling()
    }
}
