//
//  Project.swift
//  Pollock
//
//  Created by Skylar Schipper on 7/19/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

internal final class Project : NSObject, Serializable {
    let header: Header

    override init() {
        self.header = Header()
        super.init()
    }

    fileprivate var _currentCanvas: Canvas?
    var currentCanvas: Canvas {
        get {
            if let canvas = self._currentCanvas {
                return canvas
            }
            if let canvas = self.canvases.first {
                self._currentCanvas = canvas
                return canvas
            }
            let canvas = Canvas(atIndex: 0)
            self.canvases.insert(canvas)
            self._currentCanvas = canvas
            return canvas
        }
    }

    fileprivate var canvases: Set<Canvas> = []

    func serialize() throws -> [String : Any] {
        let header = try self.header.serialize()
        let canvases = try self.canvases.sorted { $0.index < $1.index }.map { try $0.serialize() }
        return [
            "header": header,
            "canvases": canvases,
            "_type": "project"
        ]
    }

    init(_ payload: [String : Any]) throws {
        self.header = try Header.load(payload["header"])
        guard let canvasesHashes = payload["canvases"] as? [[String: Any]] else {
            throw SerializerError("Missing canvases")
        }
        let canvases = try canvasesHashes.map { try Canvas($0) }
        self.canvases = Set(canvases)
    }
}

extension Project {
    func addCanvas(_ canvas: Canvas) throws {
        if self.hasCanvas(withIndex: canvas.index) {
            throw ProjectError(.existingCanvas, "There is already at canvas with index \(canvas.index)")
        }
        self.canvases.insert(canvas)
    }

    func setActiveCanvas(withIndex index: Int) throws {
        if let canvas = self.canvas(withIndex: index) {
            self._currentCanvas = canvas
        } else {
            let canvas = Canvas(atIndex: index)
            try self.addCanvas(canvas)
            self._currentCanvas = canvas
        }
    }

    func hasCanvas(withIndex index: Int) -> Bool {
        return self.canvas(withIndex: index) != nil
    }

    func canvas(withIndex index: Int) -> Canvas? {
        for canvas in self.canvases {
            if canvas.index == index {
                return canvas
            }
        }
        return nil
    }

    func removeCanvas(withIndex index: Int) -> Canvas? {
        guard let canvas = self.canvas(withIndex: index) else {
            return nil
        }
        self.canvases.remove(canvas)
        return canvas
    }
}

internal struct ProjectError : CustomNSError {
    internal enum Code : Int {
        case generic        = 0
        case existingCanvas = 1

        var localizedDescription: String {
            switch self {
            case .generic:
                return NSLocalizedString("An unknown error occured", comment: "ProjectError Code generic")
            case .existingCanvas:
                return NSLocalizedString("Project already contains a canvas for that index", comment: "ProjectError Code existingCanvas")
            }
        }
    }

    let code: Code
    let message: String?

    init(_ code: Code, _ message: String? = nil) {
        self.code = code
        self.message = message
    }

    // MARK: - NSError stuff
    public static var errorDomain: String {
        return "PollockProjectErrorDomain"
    }

    /// The error code within the given domain.
    public var errorCode: Int {
        return self.code.rawValue
    }

    /// The user-info dictionary.
    public var errorUserInfo: [String : Any] {
        return [
            NSLocalizedDescriptionKey: self.code.localizedDescription,
            NSLocalizedFailureReasonErrorKey: self.message ?? NSLocalizedString("An unknown failure occurred", comment: "ProjectError default failure reason")
        ]
    }
}
