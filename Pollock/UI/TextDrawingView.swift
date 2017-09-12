//
//  TextDrawingView.swift
//  Pollock
//
//  Created by Skylar Schipper on 9/12/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import UIKit

internal class TextDrawingView : UIView {
    let drawing: Drawing

    init(_ drawing: Drawing) {
        self.drawing = drawing
        self.centerConstraint = CenterConstraint(nil, nil)
        super.init(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 24.0))
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = UIColor.orange
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var drawingView: DrawingView? {
        return self.superview as? DrawingView
    }

    private var centerConstraint: CenterConstraint {
        willSet {
            NSLayoutConstraint.deactivate(self.centerConstraint.constraints)
        }
        didSet {
            self.superview?.addConstraints(self.centerConstraint.constraints)
            self.superview?.setNeedsLayout()
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 50.0, height: 24.0)
    }

    // MARK: - State
    func beginEditing() throws {
        try self.updateLocation()
    }

    func endEditing() throws {
        print("End Editing")
    }

    private func updateLocation() throws {
        guard let location = drawing.allPoints.last?.location else {
            throw TextDrawingViewError.noLocation
        }
        self.centerConstraint = CenterConstraint(
            NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: self.superview, attribute: .right, multiplier: location.xOffset, constant: 0.0),
            NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: self.superview, attribute: .bottom, multiplier: location.yOffset, constant: 0.0)
        )
    }
}

internal enum TextDrawingViewError : Error {
    case noLocation
}

fileprivate struct CenterConstraint {
    let x: NSLayoutConstraint?
    let y: NSLayoutConstraint?

    init(_ x: NSLayoutConstraint?, _ y: NSLayoutConstraint?) {
        self.x = x
        self.y = y
    }

    var constraints: [NSLayoutConstraint] {
        var con: [NSLayoutConstraint] = []
        if let x = self.x {
            con.append(x)
        }
        if let y = self.y {
            con.append(y)
        }
        return con
    }
}
