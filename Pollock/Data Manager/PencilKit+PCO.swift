//
//  PencilKit+PCO.swift
//  Pencil Kit Practice
//
//  Created by Erik Bye on 4/26/21.
//

import Foundation
import PencilKit

struct PollockConstants  {
    static let canvases = "canvases"
}

@available(iOS 10.0, *)
struct PKDrawingHelper {
    static func dict(forColor color: UIColor) -> [String: Any] {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return [
            "alpha" : min(max(alpha, 0), 1),            //0 - 1
            "red" : min(max(red * 255.0, 0), 255),      //0 - 255
            "blue" : min(max(blue * 255.0, 0), 255),    //0 - 255
            "green" : min(max(green * 255.0, 0), 255)   //0 - 255
        ]
    }

    static func color(forDict dict: [String: Any]) -> UIColor {
        let red = dict["red"] as? CGFloat ?? 0
        let alpha = dict["alpha"] as? CGFloat ?? 0
        let _ = dict["name"] as? String ?? ""
        let blue = dict["blue"] as? CGFloat ?? 0
        let green = dict["green"] as? CGFloat ?? 0

        return UIColor(displayP3Red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: alpha)
    }
}

@available(iOS 14.0, *)
struct PKDrawingExtractor {
    static func unserialize(_ payload: [String : Any]) -> [PKDrawing] {
        if let canvases = payload["canvases"] as? [[String: Any]] {
            var pkDrawings = [PKDrawing]()
            canvases.forEach { (canvas) in
                if let drawing = try? PKDrawing(canvas) {
                    pkDrawings.append(drawing)
                    //need to update poin
                }
            }
            return pkDrawings
        }
        return []
    }

    @available(iOS 14.0, *)
    static func upscalePoints(ofDrawing drawing: PKDrawing, withSize size: CGSize) -> PKDrawing {
        var newDrawingStrokes = [PKStroke]()
        for stroke in drawing.strokes {
            let previousInk = stroke.ink

            var newPoints = [PKStrokePoint]()
            stroke.path.forEach { (point) in
                let newLocation = CGPoint(x: point.location.x * size.width, y: point.location.y * size.height)
                let newPoint = PKStrokePoint(location: newLocation,
                                             timeOffset: point.timeOffset,
                                             size: point.size,
                                             opacity: point.opacity, force: point.force,
                                             azimuth: point.azimuth, altitude: point.altitude)
                newPoints.append(newPoint)
            }
            let newPath = PKStrokePath(controlPoints: newPoints, creationDate: Date())
            newDrawingStrokes.append(PKStroke(ink: previousInk, path: newPath))
        }
        return PKDrawing(strokes: newDrawingStrokes)
    }
    
    @available(iOS 14.0, *)
    static func downscalePoints(ofDrawing drawing: PKDrawing, withSize size: CGSize) -> PKDrawing {
        var newDrawingStrokes = [PKStroke]()
        for stroke in drawing.strokes {
            let previousInk = stroke.ink

            var newPoints = [PKStrokePoint]()
            stroke.path.forEach { (point) in
                let transformedPoint = point.location.applying(stroke.transform) //apply lasso transform
                print(point.size)
                let newLocation = CGPoint(x: transformedPoint.x / size.width, y: transformedPoint.y / size.height)

                let newPoint = PKStrokePoint(location: newLocation,
                                             timeOffset: point.timeOffset,
                                             size: point.size,
                                             opacity: point.opacity, force: point.force,
                                             azimuth: point.azimuth, altitude: point.altitude)
                newPoints.append(newPoint)
            }
            let newPath = PKStrokePath(controlPoints: newPoints, creationDate: Date())
            newDrawingStrokes.append(PKStroke(ink: previousInk, path: newPath))
        }
        return PKDrawing(strokes: newDrawingStrokes)
    }
}

//PCO Canvas == PKDrawing
//PCO Drawings == PKStroke
//PCO Point == PKStrokePoint

@available(iOS 13.0, *)
extension PKDrawing: Serializable {
    public func serialize() throws -> [String : Any] {
        let header = try self.header()
        
        var drawings: [[String: Any]] = []
        if #available(iOS 14.0, *) {
            drawings = try self.strokes.map{ try $0.serialize() }
        }

        let canvases: [String: Any] = ["text": [],
                                       "drawings": drawings,
                                       "_type": "canvas",
                                       "index": 0
        ]
        return [
            "header": header,
            "canvases": [canvases],
            "_type": "project"
        ]
    }

    func header() throws -> [String: Any] {
        return [
            "version": 1,
            "projectID": UUID().uuidString,  //TODO: Need to generate UUID for the drawing/project
            "_type": "header"
        ]
    }

    public init(_ payload: [String : Any]) throws {
        guard #available(iOS 14.0, *) else {
            if #available(iOS 14.0, *) {
                self.init(strokes: [])
            } else {
                self.init()
            }
            return
        }
        if let payloadTexts = payload["text"] as? [[String: Any]] {
            var texts = [PKText]()
            try payloadTexts.forEach { (textPaylod) in
                let text = try PKText(textPaylod)
                texts.append(text)
            }

            let _ = texts.count
        }

        if let drawings = payload["drawings"] as? [[String: Any]] {
            var pkStrokes = [PKStroke]()
            drawings.forEach { (drawing) in
                var toolSize = CGSize(width: 1, height: 1)
                var toolForce: CGFloat = 1
                if let tool = drawing["tool"] as? [String: Any] {
                    toolForce = tool["forceSensitivity"] as? CGFloat ?? 0
                    let lineWidth = tool["lineWidth"] as? CGFloat ?? 0
                    let _ = tool["name"]
                    toolSize = PKDrawing.toolSize(fromLineWidth: lineWidth)
                }
                var inkColor = UIColor.black
                if let color = drawing["color"] as? [String: Any] {
                    inkColor = PKDrawingHelper.color(forDict: color)
                }

                if let points = drawing["points"] as? [[String: Any]] {
                    var pkPoints = [PKStrokePoint]()
                    points.forEach { (pointJson) in
                        if let point = try? PKStrokePoint(pointJson) {
                            pkPoints.append(point)
                        }
                    }
                    var newPoints = [PKStrokePoint]()
                    pkPoints.forEach { (point) in
                        toolSize = point.size == CGSize.zero ? toolSize : point.size
                        print("\(toolSize) & \(point.size)")
                        let newPoint = PKStrokePoint(location: point.location, timeOffset: TimeInterval.init(), size: toolSize, opacity: 2, force: toolForce, azimuth: 9, altitude: 1)
                        newPoints.append(newPoint)
                    }
                    let strokePath = PKStrokePath(controlPoints: newPoints, creationDate: Date())
                    let stroke = PKStroke(ink: PKInk(.pen, color: inkColor), path: strokePath)
                    pkStrokes.append(stroke)
                }
            }
            self.init(strokes: pkStrokes)
            return
        }
        self.init(strokes: [])
    }

    static func toolSize(fromLineWidth lineWidth: CGFloat) -> CGSize {
        // Music Stand seems to store line width between 0 and 0.075
        // Music Stand normalizes these values in Pollock by using a scale of 1000, so between 0 and 75

        // PencilKit line width seems to go bettween 3 and 13
        // 175 seems to normalize for these values
        return CGSize(width: lineWidth * 300, height: lineWidth * 300)
    }
}

//PKStroke == PCO Drawing

@available(iOS 14.0, *)
extension PKStroke: Pollock.Serializable {
    public init(_ payload: [String : Any]) throws {

        //this isn't used and instead PKDrawing's init does all the conversions
        self = PKStroke(ink: PKInk(.pen), path: PKStrokePath(controlPoints: [], creationDate: Date()))
    }

    public func serialize() throws -> [String : Any] {
        var points: [[String: Any]] = []


        var maxLineWidth: CGFloat = 0
        var maxLineHeight: CGFloat = 0


        // The path is a uniform cubic B-Spline and holds control points
        // To get points on the center of the path, need to use:
        //  path.interpolatedPoints(by: .distance(CGFloat))

        //  a distance around 0.1 seems to be good



        //        for point in path.interpolatedPoints(by: .distance(0.1)) {
        //            maxLineWidth = max(maxLineWidth, point.size.width)
        //            maxLineHeight = max(maxLineHeight, point.size.height)
        //            if let dictPoint = try? point.serialize() {
        //                points.append(dictPoint)
        //            }
        //        }


        //To get eraser paths you need to use the following:
        for pathRange in maskedPathRanges {
            //each path range is a stroke?
            for point in path.interpolatedPoints(in: pathRange, by: .distance(0.01)) {   //adjusting the distance gives more accurate drawings, but requires more resources to save
                maxLineWidth = max(maxLineWidth, point.size.width)
                maxLineHeight = max(maxLineHeight, point.size.height)
                if let dictPoint = try? point.serialize() {
                    points.append(dictPoint)
                }
            }
        }

        //This generates a lot more points when we may not need so many.
        //        for index in path.indices {
        //            let point = path.interpolatedPoint(at: CGFloat(index))
        //            maxLineWidth = max(maxLineWidth, point.size.width)
        //            maxLineHeight = max(maxLineHeight, point.size.height)
        //            if let dictPoint = try? point.serialize() {
        //                points.append(dictPoint)
        //            }
        //        }

        //To get the stroke color we pull it from the ink
        let color = PKDrawingHelper.dict(forColor: self.ink.color)

        // To get the line width we're currently looking at each PKStrokePoint and using the point with the largest width or height.  To translate it back to music stand sizes we divide by a scale
        let lineWidthScaleToMusicStand: CGFloat = 300
        var tool = try self.ink.serialize()
        let lineWidth = max(maxLineHeight, maxLineWidth) / lineWidthScaleToMusicStand
        tool["lineWidth"] = lineWidth

        return [
            "drawingID": UUID().uuidString,  //TODO need to set a uuid on the actual stroke somehow
            "version": 1,  //TODO: Same as above, but need to hold a version somewhere
            "tool": tool,
            "points": points,
            "isCulled": false,  //TODO: Figure out what is culled does
            "color": color,
            "isSmoothingEnabled": false, //Appears to always be true
            "_type": "drawing"
        ]
    }



}

@available(iOS 14.0, *)
extension PKInk: Pollock.Serializable {
    public init(_ payload: [String : Any]) throws {
        self.init(InkType.pen)
    }

    public func serialize() throws -> [String : Any] {
        return [
            "_type" : "tool",
            "forceSensitivity" : 1,
            "lineWidth" : self.inkType.defaultWidth,
            "name" : toolName(),
            "version" : 1
        ]
    }

    func toolName() -> String {
        switch self.inkType {
            case .pen:
                return "pen"
            case .marker:
                return "highlighter"
            default:
                return "pen"
        }
    }
}


struct PKText: Serializable {

    let id: String
    let location: CGPoint
    let fontName: String
    let fontSize: NSNumber
    let version: NSNumber
    let value: String
    let color: UIColor


    init(id: String, location: CGPoint, fontName: String, fontSize: NSNumber, version: NSNumber, value: String, color: UIColor) {
        self.id = id
        self.location = location
        self.fontName = fontName
        self.fontSize = fontSize
        self.version = version
        self.value = value
        self.color = color
    }

    init(_ payload: [String : Any]) throws {
        let id = payload["textID"] as? String ?? "not-set"
        let fontName = payload["fontName"] as? String ?? "Arial"
        let fontSize = payload["fontSize"] as? NSNumber ?? 0

        let value = payload["value"] as? String ?? "value-not-set"

        let version = payload["version"] as? NSNumber ?? 0

        let location = payload["location"] as? [String: Any] ?? [:]

        let yOffset = location["yOffset"] as? NSNumber ?? 0
        let xOffset = location["xOffset"] as? NSNumber ?? 0


        let payloadColor = payload["color"] as? [String: Any] ?? [:]
        var convertedColor = UIColor.white
        if #available(iOS 10.0, *) {
            convertedColor = PKDrawingHelper.color(forDict: payloadColor)
        }

        self.init(id: id, location: CGPoint(x: xOffset.doubleValue, y: yOffset.doubleValue), fontName: fontName, fontSize: fontSize, version: version, value: value, color: convertedColor)
    }

    func serialize() throws -> [String : Any] {
        var colorDict: [String: Any] = [:]
        if #available(iOS 10.0, *) {
            colorDict = PKDrawingHelper.dict(forColor: self.color)
        }
        return ["location": [
            "xOffset": location.x,
            "yOffset": location.y
            ],
        "textID": UUID().uuidString,
        "fontSize": fontSize.doubleValue,
        "color": colorDict,
        "fontName": fontName,
        "version": version,
        "value": value
        ]
    }
}

@available(iOS 14.0, *)
extension PKStrokePoint: Serializable {
    public init(_ payload: [String : Any]) throws {
        let location = payload["location"] as? [String: Any] ?? [:]

        let yOffset = location["yOffset"] as? NSNumber ?? 0
        let xOffset = location["xOffset"] as? NSNumber ?? 0

        let size = payload["size"] as? [String: Any] ?? [:]
        let width = size["width"] as? NSNumber ?? 0
        let height = size["height"] as? NSNumber ?? 0

        let force = payload["force"] as? NSNumber ?? 0

        self.init(location: CGPoint(x: xOffset.doubleValue, y: yOffset.doubleValue), timeOffset: 0, size: CGSize(width: width.doubleValue, height: height.doubleValue), opacity: 1.0, force: CGFloat(truncating:force), azimuth: 1.23, altitude: 0.8)
    }

    public func serialize() throws -> [String : Any] {
        return ["previous": [
            "xOffset": self.location.x,
            "yOffset": self.location.y
        ],
        "isPredictive": false,
        "_type": "point",
        "force": 1,
        "size": [
            "width": self.size.width,
            "height": self.size.height,
        ],
        "location": [
            "xOffset": self.location.x,
            "yOffset": self.location.y  //TODO: This location data is not stored as percent (0-1) and instead as a full location.. need to convert back to 0-1... needs a size?
        ]    //might want to also save the b-spline location for accurate pencil kit rendering.
        ]
    }
}
