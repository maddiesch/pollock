//
//  TextDrawingView.swift
//  Pollock
//
//  Created by Skylar Schipper on 9/12/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import UIKit


internal protocol TextDrawingViewDelegate : class {
    func textViewShouldEndEditing(_ textView: TextDrawingView, _ shouldDelete: Bool)
    func textDrawingToolbarDelegate() -> TextDrawingToolbarDelegate
    
}

internal class TextDrawingView : UIView, UITextViewDelegate {
    let text: Text
    
    public weak var textDrawingToolbarViewDelegate: TextDrawingToolbarDelegate?
    public weak var delgate: TextDrawingViewDelegate?

    init(_ text: Text) {
        self.text = text
        self.centerConstraint = CenterConstraint(nil, nil)
        super.init(frame: CGRect(x: 0.0, y: 0.0, width: 50.0, height: 24.0))
        self.string = text.value
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = UIColor(white: 0.6, alpha: 0.3)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var drawingView: JSONDrawingView? {
        return self.superview as? JSONDrawingView
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
        let rect = self.text.textRectForCanvasSize(self.superview?.bounds.size ?? CGSize.zero)
        return CGSize(width: max(50.0, rect.width), height: rect.height)
    }

    var string: String? {
        set {
            if let string = newValue {
                let attribs = self.text.defaultAttributesForSize(self.superview?.bounds.size ?? CGSize.zero)
                self.textView.attributedText = NSAttributedString(string: string, attributes: attribs)
            } else {
                self.textView.attributedText = nil
            }
        }
        get {
            return self.textView.text
        }
    }

    private lazy var textView: UITextView = {
        let field = UITextView(frame: self.bounds)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.delegate = self
        field.isScrollEnabled = false
        field.textContainerInset = UIEdgeInsets.zero
        field.textContainer.lineFragmentPadding = 0.0
        field.backgroundColor = .clear

        self.addSubview(field)
        self.addConstraints([
            NSLayoutConstraint(item: field, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: field, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: field, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: field, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0),
            ])
        return field
    }()

    var textColor: UIColor? {
        set {
            self.textView.textColor = newValue
        }
        get {
            return self.textView.textColor
        }
    }

    // MARK: - State
    func beginEditing() throws {
        self.updateLocation()

        self.textView.font = self.text.fontForSize(self.superview?.bounds.size ?? CGSize.zero)
        self.string = self.text.value
        self.textView.textColor = self.text.color.uiColor

        self.setupInputAccessoryView()

        self.textView.becomeFirstResponder()

        self.invalidateIntrinsicContentSize()
        self.superview?.setNeedsLayout()
    }

    private func setupInputAccessoryView() {
        let toolbar = self.delgate?.textDrawingToolbarDelegate().createToolbarView()
        if let bar = toolbar {
            bar.doneButton.addTarget(self, action: #selector(doneButtonAction), for: .touchUpInside)
            bar.fontButton.addTarget(self, action: #selector(fontPickerButtonAction), for: .touchUpInside)
            bar.deleteButton.addTarget(self, action: #selector(deleteButtonAction), for: .touchUpInside)
            bar.fontSizeSlider.addTarget(self, action: #selector(fontSizeSliderValueChanged), for: .valueChanged)
            bar.fontSize = Float(self.text.fontSize)
            bar.fontName = self.text.font.rawValue
        }
        self.textView.inputAccessoryView = toolbar
    }

    func endEditing() throws {
        self.textView.resignFirstResponder()
        self.text.value = self.string ?? ""
    }

    private func updateLocation() {
        let location = self.text.location
        self.centerConstraint = CenterConstraint(
            NSLayoutConstraint(item: self, attribute: .left, relatedBy: .equal, toItem: self.superview, attribute: .right, multiplier: location.xOffset, constant: 0.0),
            NSLayoutConstraint(item: self, attribute: .top , relatedBy: .equal, toItem: self.superview, attribute: .bottom, multiplier: location.yOffset, constant: 0.0)
        )
    }

    func textViewDidChange(_ textView: UITextView) {
        self.invalidateIntrinsicContentSize()
        self.superview?.setNeedsLayout()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.delgate?.textViewShouldEndEditing(self, false)
        return false
    }

    @objc private func doneButtonAction(_ sender: UIButton) {
        self.delgate?.textViewShouldEndEditing(self, false)
    }

    @objc private func deleteButtonAction(_ sender: UIButton) {
        self.delgate?.textViewShouldEndEditing(self, true)
    }

    @objc private func fontPickerButtonAction(_ sender: UIButton) {
        switch self.text.font {
        case .arial:
            self.text.font = .tnr
        case .tnr:
            self.text.font = .arial
        }
        self.textView.font = self.text.fontForSize(self.superview?.bounds.size ?? CGSize.zero)
        let notif = Notification(name: .textDrawingFontDidChange, object: self.text.font, userInfo: nil)
        NotificationCenter.default.post(notif)
    }

    @objc private func fontSizeSliderValueChanged(_ sender: UISlider) {
        self.text.fontSize = CGFloat(sender.value)
        self.textView.font = self.text.fontForSize(self.superview?.bounds.size ?? CGSize.zero)
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
