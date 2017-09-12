//
//  TextContent.swift
//  Pollock
//
//  Created by Skylar Schipper on 9/8/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation


@objc(POLTextContent)
public final class TextContent : NSObject, Serializable {
    public static let key = "textContent"

    public var fontName: String = "system"

    public var fontSize: CGFloat = 0.4

    public var value: String = "Text Drawing"

    public func serialize() throws -> [String : Any] {
        return [
            "fontName": self.fontName
        ]
    }

    public init(_ payload: [String : Any]) throws {

    }
}
