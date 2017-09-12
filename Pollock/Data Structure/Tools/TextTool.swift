//
//  TextTool.swift
//  Pollock
//
//  Created by Skylar Schipper on 9/8/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

@objc(POLTextTool)
public final class TextTool : Tool {
    public override var name: String {
        return "text"
    }

    public override var isSmoothingSupported: Bool {
        return false
    }

    public override init() {
        super.init()

        self.version = PollockCurrentVersion
    }

    public required init(_ payload: [String : Any]) throws {
        super.init()
        self.version = try Serializer.validateVersion(payload["version"], "TextTool")
    }

    public override var localizedUndoName: String {
        return Localized("pollock.tool.undo-name-text")
    }

    public override var localizedName: String {
        return Localized("pollock.tool.name-text")
    }

    internal override func performDrawingInContext(_ settings: RenderSettings, _ ctx: CGContext, path: CGPath, size: CGSize, drawing: Drawing, backgroundRenderer bg: BackgroundRenderer?) throws {
        guard let location = path.getPoints().last else {
            return
        }
        guard let content = drawing.metadata[TextContent.key] as? TextContent else {
            return
        }
        print(location)
        print(drawing.metadata)
        print(content)
    }
}
