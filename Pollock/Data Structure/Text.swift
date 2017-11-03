//
//  Text.swift
//  Pollock
//
//  Created by Skylar Schipper on 9/19/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import UIKit

internal final class Text : Serializable {
    public static let defaultFontSize: CGFloat = 0.025

    private let version: PollockVersion

    internal let id: UUID
    internal var color: Color
    internal var location: Location
    internal var value: String
    internal var font: Font
    internal var fontSize: CGFloat

    internal var isRenderable: Bool = true

    internal init(_ value: String, _ color: Color, _ location: Location, _ font: Font, _ fontSize: CGFloat) {
        self.version = PollockCurrentVersion
        self.id = UUID()
        self.value = value
        self.color = color
        self.location = location
        self.font = font
        self.fontSize = fontSize
    }

    func serialize() throws -> [String : Any] {
        return [
            "version": self.version,
            "textID": self.id.uuidString,
            "location": try self.location.serialize(),
            "color": try self.color.serialize(),
            "value": self.value,
            "fontName": self.font.rawValue,
            "fontSize": self.fontSize
        ]
    }

    init(_ payload: [String : Any]) throws {
        _ = try Serializer.validateVersion(payload["version"], "Text")
        self.version = PollockCurrentVersion
        self.id = try Serializer.decodeUUID(payload["textID"])
        guard let location = payload["location"] as? [String: Any] else {
            throw SerializerError("Invalid Location")
        }
        self.location = try Location(location)
        self.color = try Color(payload["color"] as? [String: Any] ?? [:])
        self.value = payload["value"] as? String ?? ""
        self.font = Font(rawValue: payload["fontName"] as? String ?? Font.arial.rawValue) ?? Font.arial
        self.fontSize = payload["fontSize"] as? CGFloat ?? 0.025
    }

    internal func draw(inContext ctx: CGContext, size: CGSize, settings: RenderSettings) throws {
        guard self.isRenderable else {
            return
        }
        let rect = self.textRectForCanvasSize(size)
        let attributes = self.defaultAttributesForSize(size)
        (self.value as NSString).draw(in: rect, withAttributes: attributes)
    }

    internal func fontForSize(_ size: CGSize) -> UIFont {
        let fontSize = size.height * self.fontSize
        switch self.font {
        case .arial:
            return UIFont(name: "Arial", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        case .tnr:
            return UIFont(name: "Times New Roman", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        }
    }

    internal func defaultAttributesForSize(_ size: CGSize) -> [NSAttributedStringKey: Any] {
        return [
            .font: self.fontForSize(size),
            .kern: NSNull(),
            .foregroundColor: self.color.uiColor,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.lineSpacing = 1.0
                return style
            }()
        ]
    }


    internal func textRectForCanvasSize(_ size: CGSize) -> CGRect {
        let bouding = (self.value as NSString).size(withAttributes: self.defaultAttributesForSize(size))
        let point = self.location.point(forSize: size)
        return CGRect(origin: point, size: bouding).integral
    }
}

public enum Font : String {
    case arial = "Arial"
    case tnr   = "Times New Roman"
}
