//
//  Color.swift
//  Pollock
//
//  Created by Skylar Schipper on 8/1/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

public struct Color : Equatable, Serializable {
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

    public enum Name : String {
        case red    = "red"
        case green  = "green"
        case blue   = "blue"
        case orange = "orange"
        case yellow = "yellow"
        case purple = "purple"
        case black  = "black"
        case white  = "white"

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
            case .purple:
                return Color(255.0, 0.0, 255.0, 1.0, self)
            case .green:
                return Color(0.0, 255.0, 0.0, 1.0, self)
            case .black:
                return Color(0.0, 0.0, 0.0, 1.0, self)
            case .white:
                return Color(255.0, 255.0, 255.0, 1.0, self)
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
