//
//  TextDrawingToolbarView.swift
//  Pollock
//
//  Created by Skylar Schipper on 9/18/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation
import UIKit

public protocol TextDrawingToolbarDelegate : class {
    func createToolbarView() -> TextDrawingToolbarView
}

open class TextDrawingToolbarView : UIView {
    public var sliderRange: ClosedRange<Float> = (0.01 ... 0.4) {
        didSet {
            self.fontSizeSlider.minimumValue = self.sliderRange.lowerBound
            self.fontSizeSlider.maximumValue = self.sliderRange.upperBound
        }
    }

    public var fontSize: Float {
        get {
            return self.fontSizeSlider.value
        }
        set {
            self.fontSizeSlider.value = newValue
        }
    }

    public var fontName: String = "Arial" {
        didSet {
            self.fontButton.setTitle(self.fontName, for: .normal)
        }
    }

    public init() {
        super.init(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 58.0))
        self.backgroundColor = KeyboardColor
        self.translatesAutoresizingMaskIntoConstraints = true
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        NotificationCenter.default.addObserver(self, selector: #selector(textDrawingFontDidChangeNotification), name: .textDrawingFontDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(textDrawingFontSizeDidChangeNotification), name: .textDrawingFontSizeDidChange, object: nil)

        self.contentView.addArrangedSubview(self.topContentView)
        self.contentView.addArrangedSubview(self.bottomContentView)

        do {
            self.topContentView.addArrangedSubview(self.spacerView)
            self.topContentView.addArrangedSubview(self.deleteButton)
            self.topContentView.addArrangedSubview(self.doneButton)
        }

        do {
            self.bottomContentView.addArrangedSubview(self.fontSizeSlider)
        }

        self.updateLayoutForTraitCollection(self.traitCollection)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    open override var intrinsicContentSize: CGSize {
        switch self.traitCollection.horizontalSizeClass {
        case .compact:
            return CGSize(width: UIView.noIntrinsicMetric, height: 96.0)
        default:
            return CGSize(width: UIView.noIntrinsicMetric, height: 48.0)
        }
    }

    private lazy var contentView: UIStackView = {
        let view = UIStackView(frame: self.bounds)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 4.0
        view.alignment = .fill
        view.distribution = .fill

        self.addSubview(view)
        if #available(iOS 11.0, *) {
            self.addConstraints([
                NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 8.0),
                NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: -8.0),
                NSLayoutConstraint(item: view, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 8.0),
                NSLayoutConstraint(item: view, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -8.0),
            ])
        } else {
            // Fallback on earlier versions
        }
        return view
    }()

    public lazy var topContentView: UIStackView = {
        let view = UIStackView(frame: self.bounds)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 12.0
        view.alignment = .fill
        view.distribution = .fill

        return view
    }()

    public lazy var bottomContentView: UIStackView = {
        let view = UIStackView(frame: self.bounds)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 12.0
        view.alignment = .fill
        view.distribution = .fill

        return view
    }()

    internal lazy var fontButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = KeyboardColor
        button.setTitleColor(UIColor.black, for: .normal)
        button.setTitleColor(UIColor.darkGray, for: .highlighted)
        button.setTitle(self.fontName, for: .normal)
        button.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        button.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)

        return button
    }()

    internal lazy var doneButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = KeyboardColor
        button.setTitleColor(UIColor.black, for: .normal)
        button.setTitleColor(UIColor.darkGray, for: .highlighted)
        button.setTitle(Localized("pollock.text-toolbar.done-button-title"), for: .normal)
        button.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        button.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)

        return button
    }()

    internal lazy var deleteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = KeyboardColor
        button.setTitleColor(UIColor.black, for: .normal)
        button.setTitleColor(UIColor.darkGray, for: .highlighted)
        button.setTitle(Localized("pollock.text-toolbar.delete-button-title"), for: .normal)
        button.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        button.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)

        return button
    }()

    internal lazy var fontSizeSlider: UISlider = {
        let slider = UISlider(frame: CGRect(x: 0.0, y: 0.0, width: 320.0, height: 30.0))
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        slider.minimumValue = self.sliderRange.lowerBound
        slider.maximumValue = self.sliderRange.upperBound
        slider.value = self.sliderRange.lowerBound

        return slider
    }()

    private lazy var spacerView: UIView = {
        let spacer = UIView(frame: CGRect.zero)
        spacer.backgroundColor = UIColor.clear
        spacer.setContentHuggingPriority(UILayoutPriority.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)

        return spacer
    }()

    open override func draw(_ rect: CGRect) {
        AccentColor.set()

        do {
            let width: CGFloat = 1.0
            let padding: CGFloat = 0.0
            let frame = CGRect(x: padding, y: self.bounds.height - width, width: self.bounds.width - (padding * 2.0), height: width).integral
            UIBezierPath(rect: frame).fill()
        }
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.updateLayoutForTraitCollection(self.traitCollection)
    }

    private func updateLayoutForTraitCollection(_ traitCollection: UITraitCollection) {
        switch traitCollection.horizontalSizeClass {
        case .compact:
            self.contentView.axis = .vertical
            self.spacerView.isHidden = false
            self.contentView.insertArrangedSubview(self.topContentView, at: 0)
            self.topContentView.insertArrangedSubview(self.fontButton, at: 0)
        default:
            self.contentView.axis = .horizontal
            self.spacerView.isHidden = true
            self.contentView.insertArrangedSubview(self.bottomContentView, at: 0)
            self.bottomContentView.insertArrangedSubview(self.fontButton, at: 0)
        }
        self.invalidateIntrinsicContentSize()
    }

    @objc private func textDrawingFontDidChangeNotification(_ notif: Notification) {
        guard let font = notif.object as? Font else {
            return
        }
        self.fontName = font.rawValue
    }

    @objc private func textDrawingFontSizeDidChangeNotification(_ notif: Notification) {
    }
}

fileprivate let KeyboardColor = UIColor(red: 0.820, green: 0.835, blue: 0.859, alpha: 1.0)
fileprivate let AccentColor = UIColor(red: 0.725, green: 0.733, blue: 0.749, alpha: 1.0)
