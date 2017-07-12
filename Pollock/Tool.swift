//
//  Tool.swift
//  Pollock
//
//  Created by Skylar Schipper on 5/11/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

@objc(POLTool)
open class Tool : NSObject, Serializable {
    open var lineWidth: CGFloat {
        return 0.0
    }

    open var forceSensitivity: CGFloat {
        return 0.0
    }

    open func calculateLineWidth(forForce force: CGFloat) -> CGFloat {
        assert(self.forceSensitivity > 0.0, "Can't have a force forceSensitivity of 0")
        return self.lineWidth * (force / self.forceSensitivity)
    }

    open var name: String {
        return "tool"
    }

    open var version = 1

    public func serialize() throws -> [String : Any] {
        return [
            "name": self.name,
            "version": self.version,
            "lineWidth": self.lineWidth,
            "force": self.forceSensitivity
        ]
    }
}



@objc(POLPenTool)
public final class PenTool : Tool {
    public override var name: String {
        return "pen"
    }

    public override var lineWidth: CGFloat {
        return 16.0
    }

    public override var forceSensitivity: CGFloat {
        return 8.0
    }
}
