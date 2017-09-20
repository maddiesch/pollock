//
//  TextDrawingView.swift
//  Pollock
//
//  Created by Skylar Schipper on 9/12/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import UIKit

internal class TextDrawingView : UIView, UITextFieldDelegate {
    let text: Text

    init(_ text: Text) {
        self.text = text
        self.centerConstraint = CenterConstraint(nil, nil)
        super.init(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 24.0))
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = UIColor(white: 0.6, alpha: 0.3)
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
        let size = self.textField.intrinsicContentSize
        return CGSize(width: max(50.0, size.width), height: size.height)
    }

    lazy var textField: UITextField = {
        let field = UITextField(frame: self.bounds)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.returnKeyType = .done
        field.delegate = self

        field.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        self.addSubview(field)
        self.addConstraints([
            NSLayoutConstraint(item: field, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: field, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: field, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: field, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0),
            ])
        return field
    }()

    // MARK: - State
    func beginEditing() throws {
        self.updateLocation()

        self.textField.font = self.text.fontForSize(self.superview?.bounds.size ?? CGSize.zero)
        self.textField.text = self.text.value
        self.textField.textColor = self.text.color.uiColor

        self.setupInputAccessoryView()

        self.textField.becomeFirstResponder()

        self.invalidateIntrinsicContentSize()
        self.superview?.setNeedsLayout()
    }

    private func setupInputAccessoryView() {
        let toolbar = self.drawingView?.textDrawingToolbarViewDelegate?.createToolbarView()
        if let bar = toolbar {
            bar.doneButton.addTarget(self, action: #selector(doneButtonAction), for: .touchUpInside)
            bar.fontButton.addTarget(self, action: #selector(fontPickerButtonAction), for: .touchUpInside)
            bar.deleteButton.addTarget(self, action: #selector(deleteButtonAction), for: .touchUpInside)
            bar.fontSizeSlider.addTarget(self, action: #selector(fontSizeSliderValueChanged), for: .valueChanged)
            bar.fontSize = Float(self.text.fontSize)
            bar.fontName = self.text.font.rawValue
        }
        self.textField.inputAccessoryView = toolbar
    }

    func endEditing() throws {
        self.textField.resignFirstResponder()
        self.text.value = self.textField.text ?? ""
    }

    private func updateLocation() {
        let location = self.text.location
        self.centerConstraint = CenterConstraint(
            NSLayoutConstraint(item: self, attribute: .left, relatedBy: .equal, toItem: self.superview, attribute: .right, multiplier: location.xOffset, constant: 0.0),
            NSLayoutConstraint(item: self, attribute: .top , relatedBy: .equal, toItem: self.superview, attribute: .bottom, multiplier: location.yOffset, constant: 0.0)
        )
    }

    @objc private func textFieldDidChange(_ textField: UITextField) {
        self.invalidateIntrinsicContentSize()
        self.superview?.setNeedsLayout()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.drawingView?.textViewShouldEndEditing(self, false)
        return false
    }

    @objc private func doneButtonAction(_ sender: UIButton) {
        self.drawingView?.textViewShouldEndEditing(self, false)
    }

    @objc private func deleteButtonAction(_ sender: UIButton) {
        self.drawingView?.textViewShouldEndEditing(self, true)
    }

    @objc private func fontPickerButtonAction(_ sender: UIButton) {
        switch self.text.font {
        case .arial:
            self.text.font = .tnr
        case .tnr:
            self.text.font = .arial
        }
        self.textField.font = self.text.fontForSize(self.superview?.bounds.size ?? CGSize.zero)
        let notif = Notification(name: .textDrawingFontDidChange, object: self.text.font, userInfo: nil)
        NotificationCenter.default.post(notif)
    }

    @objc private func fontSizeSliderValueChanged(_ sender: UISlider) {
        self.text.fontSize = CGFloat(sender.value)
        self.textField.font = self.text.fontForSize(self.superview?.bounds.size ?? CGSize.zero)
        self.invalidateIntrinsicContentSize()
        self.updateLocation()
        let notif = Notification(name: .textDrawingFontSizeDidChange, object: sender.value, userInfo: nil)
        NotificationCenter.default.post(notif)
    }
}

internal enum TextDrawingViewError : Error {
    case noLocation
    case noMetadata
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

fileprivate extension UIView {
    fileprivate func firstViewController() -> UIViewController? {
        if let responder = self.next as? UIViewController {
            return responder
        }
        if let responder = self.next as? UIView {
            return responder.firstViewController()
        }
        return nil
    }
}

public extension Notification.Name {
    static let textDrawingFontSizeDidChange = Notification.Name("PollockTextDrawingFontSizeDidChangeNotificaiton")
    static let textDrawingFontDidChange = Notification.Name("PollockTextDrawingFontDidChangeNotificaiton")
}
