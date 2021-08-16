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
        
        return UIColor(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: alpha)
    }

    static var isPencilKitAvailable: Bool {
        if #available(iOS 14.0, *) {
            return true
        } else {
            return false
        }
    }
}

@available(iOS 14.0, *)
public struct PKDrawingExtractor {
    public static func unserialize(_ payload: [String : Any]) -> [PKDrawing] {
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
    public static func upscalePoints(ofDrawing drawing: PKDrawing, withSize size: CGSize) -> PKDrawing {
        var newStrokes = [PKStroke]()
        for var stroke in drawing.strokes {
            var newPoints = [PKStrokePoint]()
            var pointSize = CGSize.zero
            
            let toolName = stroke.ink.pkToolName()
            stroke.path.forEach { (point) in
                pointSize = point.size
                let newLocation = CGPoint(x: point.location.x * size.width, y: point.location.y * size.height)
                let newPoint = PKStrokePoint(location: newLocation,
                                             timeOffset: point.timeOffset,
                                             size: PKDrawingExtractor.upscaleToolSize(withToolName: toolName, fromLineWidth: pointSize.height, andSize: size),
                                             opacity: point.opacity, force: point.force,
                                             azimuth: point.azimuth, altitude: point.altitude)
                newPoints.append(newPoint)
            }
            let newPath = PKStrokePath(controlPoints: newPoints, creationDate: Date())
            
            stroke.path = newPath
            newStrokes.append(stroke)
        }
        let newDrawing = PKDrawing(strokes: newStrokes)
        return newDrawing
    }
    
    @available(iOS 14.0, *)
    public static func downscalePoints(ofDrawing drawing: PKDrawing, withSize size: CGSize) -> PKDrawing {
        var newDrawingStrokes = [PKStroke]()
        for var stroke in drawing.strokes {
            var newPoints = [PKStrokePoint]()
            var pointSize = CGSize.zero
            let toolName = stroke.ink.pkToolName()
            stroke.path.forEach { (point) in
                let transformedPoint = point.location.applying(stroke.transform) //apply lasso transform
                let newLocation = CGPoint(x: transformedPoint.x / size.width, y: transformedPoint.y / size.height)
                pointSize = point.size
                let newPoint = PKStrokePoint(location: newLocation,
                                             timeOffset: point.timeOffset,
                                             size: PKDrawingExtractor.downscaleToolSize(withToolName: toolName, fromLineWidth: pointSize.height, andSize: size),
                                             opacity: point.opacity, force: point.force,
                                             azimuth: point.azimuth, altitude: point.altitude)
                newPoints.append(newPoint)
            }
            stroke.path = PKStrokePath(controlPoints: newPoints, creationDate: Date())
            newDrawingStrokes.append(stroke)
        }
        return PKDrawing(strokes: newDrawingStrokes)
    }
    
    
    
    public static let pkPenScale: CGFloat = 0.54
    public static let pkHighlighterScale: CGFloat = 0.8

    static func upscaleToolSize(withToolName toolName: String, fromLineWidth lineWidth: CGFloat, andSize size: CGSize) -> CGSize {
        let scale = toolName == ToolNames.pen.rawValue ? PKDrawingExtractor.pkPenScale : PKDrawingExtractor.pkHighlighterScale
        
        let scaledLineSize = lineWidth * size.height * scale
        var minSize: CGFloat = 2.4
        if toolName == ToolNames.pencil.rawValue {
            minSize = 1
        }
        if scaledLineSize < minSize {
            return CGSize(width: minSize, height: minSize)
        }
        return CGSize(width: scaledLineSize, height: scaledLineSize)
    }
    
    static func downscaleToolSize(withToolName toolName: String, fromLineWidth lineWidth: CGFloat, andSize size: CGSize) -> CGSize {
        let scale = toolName == ToolNames.pen.rawValue ? PKDrawingExtractor.pkPenScale : PKDrawingExtractor.pkHighlighterScale
        
        let scaledLineSize = lineWidth / size.height / scale
        return CGSize(width: scaledLineSize, height: scaledLineSize)
    }
}

@available(iOS 13.0, *)
extension PKDrawing {
    public func serialize() throws -> [[String : Any]] {
        var drawings: [[String: Any]] = []
        if #available(iOS 14.0, *) {
            drawings = try self.strokes.map{ try $0.serialize() }
        }
        
        return drawings
    }
    
    public func eraser(fromPoint1 point1: CGPoint, toPoint2 point2: CGPoint) -> [String: Any] {
        
        var points = [[String: Any]]()
        
        let point1Json: [String: Any] = [
            "previous": [
                "xOffset": point1.x,
                "yOffset": point1.y
            ],
            "isPredictive": false,
            "_type": "point",
            "force": 1,
            "location": [
                "xOffset": point1.x,
                "yOffset": point1.y
            ]
        ]
        points.append(point1Json)
        
        let point2Json: [String: Any] = [
            "previous": [
                "xOffset": point1.x,
                "yOffset": point1.y
            ],
            "isPredictive": false,
            "_type": "point",
            "force": 1,
            "location": [
                "xOffset": point2.x,
                "yOffset": point2.y
            ]
        ]
        points.append(point2Json)
        
        let tool: [String: Any] = [
          "_type" : "tool",
          "forceSensitivity" : 1,
          "lineWidth" : 0.02,
          "name" : "eraser",
          "version" : 1
        ]
        
        let color: [String: Any] = [
            "color" : [
              "red" : 0,
              "alpha" : 1,
              "name" : "green",
              "blue" : 0,
              "green" : 255
            ]
        ]
        
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
    
    public init(_ payload: [String : Any]) throws {
        guard #available(iOS 14.0, *) else {
            if #available(iOS 14.0, *) {
                self.init(strokes: [])
            } else {
                self.init()
            }
            return
        }
        if let drawings = payload["drawings"] as? [[String: Any]] {
            var pkStrokes = [PKStroke]()
            drawings.forEach { (drawing) in
                var toolSize = CGSize(width: 1, height: 1)
                var toolForce: CGFloat = 1
                var isHighlighter = false
                var toolName = ""
                var toolType: PKInk.InkType = .pen
                if let tool = drawing["tool"] as? [String: Any] {
                    toolForce = tool["forceSensitivity"] as? CGFloat ?? 0
                    let lineWidth = tool["lineWidth"] as? CGFloat ?? 0
                    toolName = tool["name"] as? String ?? ToolNames.pen.rawValue
                    
                    isHighlighter = toolName == ToolNames.highlighter.rawValue
                    toolSize = CGSize(width: lineWidth, height: lineWidth)
                    toolType = PKDrawing.inkType(fromToolPayload: tool)
                }
                if toolName == "eraser" {
                   //Remove Eraser Data from JSON
                   return
               }
                var inkColor = UIColor.black
                if let color = drawing["color"] as? [String: Any] {
                    inkColor = PKDrawingHelper.color(forDict: color)
                    if isHighlighter {
                        //If this is a highlighter tool, force the alpha to be .6
                        inkColor = inkColor.withAlphaComponent(0.4)
                    }
                }
                
                if let points = drawing["points"] as? [[String: Any]] {
                    var pkPoints = [PKStrokePoint]()
                    points.forEach { (pointJson) in
                        do {
                            let point = try PKStrokePoint(pointJson)
                            toolSize = point.size == CGSize.zero ? toolSize : point.size
                            let newPoint = PKStrokePoint(location: point.location, timeOffset: TimeInterval.init(), size: toolSize, opacity: 1, force: toolForce, azimuth: 9, altitude: 1)
                            pkPoints.append(newPoint)
                        } catch {
                            print(error)
                        }
                    }
                    let strokePath = PKStrokePath(controlPoints: pkPoints, creationDate: Date())

                    let stroke = PKStroke(ink: PKInk(toolType, color: inkColor), path: strokePath)
                    pkStrokes.append(stroke)
                }
            }
            self.init(strokes: pkStrokes)
            return
        }
        self.init(strokes: [])
    }
    @available(iOS 14.0, *)
    public static func inkType(fromToolPayload payload: [String: Any]) -> PKInk.InkType {
        
        if let toolName = payload["pk_name"] as? String {
            if toolName == ToolNames.pen.rawValue {
                return .pen
            }
            if toolName == ToolNames.highlighter.rawValue {
                return .marker
            }
            if toolName == ToolNames.pencil.rawValue {
                return .pencil
            }
        }
        
        if let toolName = payload["name"] as? String {
            if toolName == ToolNames.pen.rawValue {
                return .pen
            }
            if toolName == ToolNames.highlighter.rawValue {
                return .marker
            }
        }
        
        return .pen
    }
    
    public func isEmpty() -> Bool {
        if #available(iOS 14.0, *) {
            return self.strokes.isEmpty
        } else {
            return true
        }
    }
}

@available(iOS 14.0, *)
extension PKStroke {
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

        
        for pathRange in maskedPathRanges {  //we wont have masked path ranges because we're not using the pixel eraser
            //each path range is a stroke?
            for point in path.interpolatedPoints(in: pathRange, by: .distance(0.01)) {   //adjusting the distance gives more accurate drawings, but requires more resources to save
                maxLineWidth = max(maxLineWidth, point.size.width)
                maxLineHeight = max(maxLineHeight, point.size.height)
                
                do {
                    let dictPoint = try point.serialize()
                    if !point.location.x.isNaN && !point.location.y.isNaN {
                        points.append(dictPoint)
                    }
                    
                } catch {
                    print(error)
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
        
        var tool = try self.ink.serialize()
        let lineWidth = max(maxLineHeight, maxLineWidth)
        tool["lineWidth"] = round(1000 * lineWidth) / 1000
        
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
    
    func calculateJSONMarkerLineWidth(lineWidth: CGFloat, canvasSize: CGSize) -> CGFloat {
        //On an iPhone with 520 the calculated width of 0.075 = 39 this is just about correct
        // 520 height min/max is 2.1/40
        // 1262 height min/max is 2.1/75  16.8
        //On an iPad with 1262 the calculated width of 0.075 = 94 which is way too big and instead I want it to be 0.046 ish
        
        //
        //40 = 0.075 iPhone
        //94 = 0.075 iPad
        return 0
    }
}

enum ToolNames: String {
    case pen
    case highlighter
    case marker
    case pencil
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
            "pk_name" : pkToolName(),
            "version" : 1
        ]
    }
    
    func toolName() -> String {
        switch self.inkType {
        case .pen:
            return ToolNames.pen.rawValue
        case .marker:
            return ToolNames.highlighter.rawValue
        default:
            return ToolNames.pen.rawValue
        }
    }
    
    func pkToolName() -> String {
        switch self.inkType {
        case .pen:
            return ToolNames.pen.rawValue
        case .marker:
            return ToolNames.highlighter.rawValue
        case .pencil:
            return ToolNames.pencil.rawValue
        default:
            return ToolNames.pen.rawValue
        }
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
        
        let timeOffset = payload["timeOffset"] as? NSNumber ?? 0
        let azimuth = payload["azimuth"] as? NSNumber ?? 1.23
        let altitude = payload["altitude"] as? NSNumber ?? 0.8
        
        self.init(location: CGPoint(x: xOffset.doubleValue, y: yOffset.doubleValue), timeOffset: TimeInterval(truncating: timeOffset), size: CGSize(width: width.doubleValue, height: height.doubleValue), opacity: 1.0, force: CGFloat(truncating:force), azimuth: CGFloat(truncating: azimuth), altitude: CGFloat(truncating: altitude))
    }
    
    public func serialize() throws -> [String : Any] {
        return ["previous": [
            "xOffset": self.location.x,
            "yOffset": self.location.y
        ],
        "isPredictive": false,
        "_type": "point",
        "force": 1,
        "pkForce": self.force,
        "timeOffset": self.timeOffset,
        "azimuth": self.azimuth,
        "altitude": self.altitude,
        "size": [
            "width": self.size.width,
            "height": self.size.height,
        ],
        "location": [
            "xOffset": self.location.x,
            "yOffset": self.location.y
        ]
        ]
    }
}
