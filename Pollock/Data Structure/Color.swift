//
//  Color.swift
//  Pollock
//
//  Created by Skylar Schipper on 8/1/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import UIKit

public struct Color : Equatable, Serializable, Codable {
    /// Named colors support
    public let name: Name?

    /// Red channel value 0.0-255.0
    public let red: Float

    /// Green channel value 0.0-255.0
    public let green: Float

    /// Blue channel value 0.0-255.0
    public let blue: Float

    /// Alpha channel value 0.0-1.0
    public let alpha: Float
    
    public init(uicolor color: UIColor) {
        let values = color.rgba
        self.red = Float(values.red * 255)
        self.blue = Float(values.blue * 255)
        self.green = Float(values.green * 255)
        self.alpha = Float(values.alpha)
        self.name = nil
    }
    
    var uicolor: UIColor {
        return UIColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: CGFloat(alpha))
    }

    public init(_ red: Float, _ green: Float, _ blue: Float, _ alpha: Float = 1.0, _ name: Name? = nil) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        self.name = name
    }

    public func serialize() throws -> [String : Any] {
        return [
            "name": self.name?.rawValue ?? "",
            "red": self.red,
            "green": self.green,
            "blue": self.blue,
            "alpha": self.alpha
        ]
    }

    public init(_ payload: [String : Any]) throws {
        if let name = Name(payload["name"]) {
            self = name.color
        } else {
            let red = payload["red"] as? Float ?? 0.0
            let green = payload["green"] as? Float ?? 0.0
            let blue = payload["blue"] as? Float ?? 0.0
            let alpha = payload["alpha"] as? Float ?? 1.0
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
            self.name = Name(red, green, blue, alpha)
        }
    }

    public enum Name : String, Codable {
        case red     = "red"
        case green   = "green"
        case blue    = "blue"
        case orange  = "orange"
        case yellow  = "yellow"
        case purple  = "purple"
        case black   = "black"
        case white   = "white"
        case fuchsia = "fuchsia"
        case lime    = "lime"
        case aqua    = "aqua"

        init?(_ name: Any?) {
            guard let name = (name as? String)?.presence else {
                return nil
            }
            self.init(rawValue: name)
        }

        init?(_ red: Float, _ green: Float, _ blue: Float, _ alpha: Float) {
            guard alpha == 1.0 else {
                return nil
            }
            switch (red, green, blue) {
            case (255.0, 0.0, 0.0):
                self = .red
            case (0.0, 255.0, 0.0):
                self = .green
            case (0.0, 0.0, 255.0):
                self = .blue
            case (255.0, 127.5, 0.0):
                self = .orange
            case (255.0, 255.0, 0.0):
                self = .yellow
            case (255.0, 0.0, 255.0):
                self = .purple
            case (0.0, 0.0, 0.0):
                self = .black
            case (255.0, 255.0, 255.0):
                self = .white
            case (0.0, 255.0, 255.0):
                self = .aqua
            default:
                return nil
            }
        }

        public var color: Color {
            switch self {
            case .orange:
                return Color(255.0, 127.5, 0.0, 1.0, self)
            case .blue:
                return Color(0.0, 0.0, 255.0, 1.0, self)
            case .red:
                return Color(255.0, 0.0, 0.0, 1.0, self)
            case .yellow:
                return Color(255.0, 255.0, 0.0, 1.0, self)
            case .purple, .fuchsia:
                return Color(255.0, 0.0, 255.0, 1.0, self)
            case .green, .lime:
                return Color(0.0, 255.0, 0.0, 1.0, self)
            case .black:
                return Color(0.0, 0.0, 0.0, 1.0, self)
            case .white:
                return Color(255.0, 255.0, 255.0, 1.0, self)
            case .aqua:
                return Color(0.0, 255.0, 255.0, 1.0, self)
            }
        }
    }

    init(_ name: Name) {
        self = name.color
    }

    public static func ==(lhs: Color, rhs: Color) -> Bool {
        return lhs.red == rhs.red && lhs.green == rhs.green && lhs.blue == rhs.blue && lhs.alpha == rhs.alpha
    }
}


extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (red, green, blue, alpha)
    }
}
