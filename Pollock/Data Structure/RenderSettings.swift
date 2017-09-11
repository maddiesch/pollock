//
//  RenderSettings.swift
//  Pollock
//
//  Created by Skylar Schipper on 9/8/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import UIKit

/// Settings used to configure the rendering.
/// These are not persisted into the saved project.
public struct RenderSettings {
    public enum HighlightStyle {
        /// Draw with a "multipy" blending mode
        case normal
        /// Draw with no blending mode, but a reduced alpha value
        case alpha
    }

    /// The method used to draw the highlighter tool
    public let highlightStyle: HighlightStyle

    /// If a color value is specified, this will render a box around a drawing that is used for culling
    public let cullingBoxColor: CGColor?

    /// If a color value is specified, this will render a box around the rect that will be drawn. (Only for the DrawingView)
    public let renderBoxColor: CGColor?

    internal let eraserFillColor: CGColor = UIColor.clear.cgColor

    public static func defaultSettings(highlightStyle: HighlightStyle = .normal, cullingBoxColor: CGColor? = nil, renderBoxColor: CGColor? = nil) -> RenderSettings {
        return RenderSettings(highlightStyle: highlightStyle, cullingBoxColor: cullingBoxColor, renderBoxColor: renderBoxColor)
    }
}
