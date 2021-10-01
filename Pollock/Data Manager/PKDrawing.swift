//
//  PencilKit+PCO.swift
//  Pencil Kit Practice
//
//  Created by Erik Bye on 4/26/21.
//

import Foundation
import PencilKit

@available(iOS 13.0, *)
extension PKDrawing {
    public func serialize() throws -> [[String : Any]] {
        var drawings: [[String: Any]] = []
        if #available(iOS 14.0, *) {
            drawings = try self.strokes.map{ try $0.serialize() }
        }
        return drawings
    }
    
    public init(_ payload: [String : Any]) throws {
        guard #available(iOS 14.0, *) else {
            self.init()
            return
        }
        if let drawings = payload["drawings"] as? [[String: Any]] {
            var pkStrokes = [PKStroke]()
            drawings.forEach { (drawing) in
                var toolSize = CGSize(width: 1, height: 1)
                var toolForce: CGFloat = 1
                var toolName = ""
                var toolType: PKInk.InkType = .pen
                if let tool = drawing["tool"] as? [String: Any] {
                    toolForce = tool["forceSensitivity"] as? CGFloat ?? 0
                    let lineWidth = tool["lineWidth"] as? CGFloat ?? 0
                    toolName = tool["name"] as? String ?? ToolNames.pen.rawValue
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
                }
                
                if let points = drawing["points"] as? [[String: Any]] {
                    var pkPoints = [PKStrokePoint]()
                    points.forEach { (pointJson) in
                        do {
                            let point = try PKStrokePoint(pointJson)
                            toolSize = point.size == CGSize.zero ? toolSize : point.size
                            let newPoint = PKStrokePoint(location: point.location, timeOffset: TimeInterval.init(), size: toolSize, opacity: point.opacity, force: toolForce, azimuth: point.azimuth, altitude: point.altitude)
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
    
    func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }
    
    public func serialize() throws -> [String : Any] {
        var points: [[String: Any]] = []
        var maxLineWidth: CGFloat = 0
        var maxLineHeight: CGFloat = 0
        var previousPoint: CGPoint?
            //each path range is a stroke?
        for point in path.interpolatedPoints(by: .distance(0.005)) {   //adjusting the distance gives more accurate drawings, but requires more resources to save
            maxLineWidth = max(maxLineWidth, point.size.width)
            maxLineHeight = max(maxLineHeight, point.size.height)
            do {
                //Remove extra points.
                if let prevPoint = previousPoint {
                    let distance = prevPoint.distance(fromPoint: point.location)
                    let threshold: CGFloat = 0.001
                    if distance < threshold {
                        continue
                    } else {
                        previousPoint = point.location
                    }
                } else {
                    previousPoint = point.location
                }
                let dictPoint = try point.serialize()
                if !point.location.x.isNaN && !point.location.y.isNaN {
                    print("=============== Point Added: \(dictPoint)")
                    points.append(dictPoint)
                }
            } catch {
                print(error)
            }
        }
        
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
        let azimuth = payload["azimuth"] as? NSNumber ?? 0
        let altitude = payload["altitude"] as? NSNumber ?? 0
        let opacity = payload["opacity"] as? NSNumber ?? 1
        
        self.init(location: CGPoint(x: xOffset.doubleValue, y: yOffset.doubleValue), timeOffset: TimeInterval(truncating: timeOffset), size: CGSize(width: width.doubleValue, height: height.doubleValue), opacity: CGFloat(truncating: opacity), force: CGFloat(truncating:force), azimuth: CGFloat(truncating: azimuth), altitude: CGFloat(truncating: altitude))
    }
    
    public func serialize() throws -> [String : Any] {
        return ["previous": [
            "xOffset": self.location.x,
            "yOffset": self.location.y
        ],
        "isPredictive": false,
        "_type": "point",
        "force": self.force,
        "timeOffset": self.timeOffset,
        "azimuth": self.azimuth,
        "opacity": self.opacity,
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

//Helpers
struct PKDrawingHelper {
    static func dict(forColor color: UIColor) -> [String: Any] {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return [
            "alpha" : Float(min(max(alpha, 0), 1)),            //0 - 1
            "red" : Float(min(max(red * 255.0, 0), 255)),      //0 - 255
            "blue" : Float(min(max(blue * 255.0, 0), 255)),    //0 - 255
            "green" : Float(min(max(green * 255.0, 0), 255))   //0 - 255
        ]
    }
    
    static func color(forDict dict: [String: Any]) -> UIColor {
        let red = dict["red"] as? Float ?? 0
        let alpha = dict["alpha"] as? Float ?? 0
        let blue = dict["blue"] as? Float ?? 0
        let green = dict["green"] as? Float ?? 0
        
        return UIColor(red: CGFloat(red / 255.0), green: CGFloat(green / 255.0), blue: CGFloat(blue / 255.0), alpha: CGFloat(alpha))
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
    @available(iOS 14.0, *)
    public static func upscalePoints(ofDrawing drawing: PKDrawing, withSize size: CGSize) -> PKDrawing {
        var newStrokes = [PKStroke]()
        for var stroke in drawing.strokes {
            var newPoints = [PKStrokePoint]()
            let toolName = stroke.ink.pkToolName()
            stroke.path.forEach { (point) in
                let newLocation = point.location.point(forSize: size)
                let maxSize = max(point.size.width, point.size.height)
                let pointSize = PKDrawingExtractor.upscaleToolSize(withToolName: toolName, fromLineWidth: maxSize, andSize: size)
                let newPoint = PKStrokePoint(location: newLocation,
                                             timeOffset: point.timeOffset,
                                             size: pointSize,
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
            let toolName = stroke.ink.pkToolName()
            stroke.path.forEach { (point) in
                let transformedPoint = point.location.applying(stroke.transform) //apply lasso transform
                let newLocation = CGPoint(x: transformedPoint.x / size.width, y: transformedPoint.y / size.height)
                let maxSize = max(point.size.width, point.size.height)
                let pointSize = PKDrawingExtractor.downscaleToolSize(withToolName: toolName, fromLineWidth: maxSize, andSize: size)
                let newPoint = PKStrokePoint(location: newLocation,
                                             timeOffset: point.timeOffset,
                                             size: pointSize,
                                             opacity: point.opacity, force: point.force,
                                             azimuth: point.azimuth, altitude: point.altitude)
                newPoints.append(newPoint)
            }
            stroke.transform = .identity  //Reset the transform after we update the points with the transform
            stroke.path = PKStrokePath(controlPoints: newPoints, creationDate: Date())
            newDrawingStrokes.append(stroke)
        }
        return PKDrawing(strokes: newDrawingStrokes)
    }
    
   
    
    public static let pkPenScale: CGFloat = 0.54
    public static let pkHighlighterScale: CGFloat = 0.8
    
    public static let pkMinPenSize: CGFloat = 2.1
    public static let pkMinPencilSize: CGFloat = 1
    
    static func minSize(forToolName toolName: String) -> CGFloat {
        if toolName == ToolNames.pencil.rawValue {
            return pkMinPencilSize  // Pencil Tool needs a smaller min size
        }
        return pkMinPenSize
    }
    
    
    // Pen Scales
    // 0.001 input, should output 3.7
    // 0.002 input, should output 2.6
    // 0.003 input, should output 1.8
    // 0.004 input, should output 1.45
    // 0.005 input, should output 1.28
    // 0.006 input, should output 1.2
    // 0.007 input, should output 1.05
    // 0.008 input, should output 1
    // 0.009 input, should output 0.92
    // 0.01 input, should output 0.8
    // 0.02 input, should output 0.65
    // 0.03 input, should output 0.6
    // 0.04 input, should output 0.57
    // 0.05 input, should output 0.0.566
    // 0.06 input, should output 0.56
    // 0.075 input, should output 0.54
    static let lineWidthJSONKeys: [CGFloat] = [0.001, 0.002, 0.003, 0.004, 0.005, 0.006, 0.007, 0.008, 0.009, 0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.075]
    static let lineWidthScaleValues: [CGFloat] = [3.7, 2.6, 1.8, 1.45, 1.28, 1.2, 1.05, 1, 0.92, 0.8, 0.65, 0.6, 0.57, 0.566, 0.56, 0.54]
    
    static func scale(forJSONLineWidth lineWidth: CGFloat) -> CGFloat {
        if lineWidth <= lineWidthJSONKeys.first! {
            return lineWidthScaleValues.first!
        }
        
        if lineWidth >= lineWidthJSONKeys.last! {
            return lineWidthScaleValues.last!
        }
        
        var minKeyIndex = 0
        var maxKeyIndex = 0
        var currentIndex = 0
        for key in lineWidthJSONKeys {
            if lineWidth >= key {
                currentIndex += 1
                continue
            } else {
                maxKeyIndex = currentIndex
                minKeyIndex = currentIndex - 1
                break
            }
        }
        
        let minKey = lineWidthJSONKeys[minKeyIndex]
        let maxKey = lineWidthJSONKeys[maxKeyIndex]
        let minScale = lineWidthScaleValues[minKeyIndex]
        let maxScale = lineWidthScaleValues[maxKeyIndex]
        
        return PKDrawingExtractor.normalized(value: lineWidth, minA: minKey, maxA: maxKey, minB: minScale, maxB: maxScale)
    }
    
    static func scale(forPKLineWidth lineWidth: CGFloat, withKeys keys: [CGFloat]) -> CGFloat {
        
        if lineWidth <= keys.first! {
            return lineWidthScaleValues.first!
        }
        
        if lineWidth >= keys.last! {
            return lineWidthScaleValues.last!
        }
        var minKeyIndex = 0
        var maxKeyIndex = 0
        var currentIndex = 0
        for key in keys {
            if lineWidth >= key {
                currentIndex += 1
                continue
            } else {
                maxKeyIndex = currentIndex
                minKeyIndex = currentIndex - 1
                break
            }
        }
        
        let minKey = keys[minKeyIndex]
        let maxKey = keys[maxKeyIndex]
        let minScale = lineWidthScaleValues[minKeyIndex]
        let maxScale = lineWidthScaleValues[maxKeyIndex]
        
        return PKDrawingExtractor.normalized(value: lineWidth, minA: minKey, maxA: maxKey, minB: minScale, maxB: maxScale)
    }
    
    static func normalized(value: CGFloat, minA: CGFloat, maxA: CGFloat, minB: CGFloat, maxB: CGFloat) -> CGFloat {
            return minB + ((value - minA) * (maxB - minB)) / (maxA - minA)
        }
    
    static func upscaleToolSize(withToolName toolName: String, fromLineWidth lineWidth: CGFloat, andSize size: CGSize) -> CGSize {
        let scale = scale(forToolName: toolName)
        let scaledLineSize = max(lineWidth * size.height, 2.1)
        
        print("==== Upscaled ============= LineWidth Before: \(lineWidth) Scale Used: \(scale) and Size: \(size.height) = Upscaled size: \(scaledLineSize)")
        return CGSize(width: scaledLineSize, height: scaledLineSize)
    }
    
    static func downscaleToolSize(withToolName toolName: String, fromLineWidth lineWidth: CGFloat, andSize size: CGSize) -> CGSize {
        let scale = scale(forToolName: toolName)
        let scaledLineSize = lineWidth / size.height
        print("==== Downscaled ============= LineWidth Before: \(lineWidth) Scale Used: \(scale) and Size: \(size.height) = Downscaled size: \(scaledLineSize)")
        return CGSize(width: scaledLineSize, height: scaledLineSize)
    }
    
    static func generatePKKeys(withSize size: CGSize) -> [CGFloat] {
        var keys: [CGFloat] = []
        var index = 0
        for key in lineWidthJSONKeys {
            let scale = lineWidthScaleValues[index]
            let value = size.height * key * scale
            keys.append(value)
            index += 1
        }
        return keys
    }
    
    static func scale(forToolName toolName: String) -> CGFloat {
        return toolName == ToolNames.pen.rawValue ? PKDrawingExtractor.pkPenScale : PKDrawingExtractor.pkHighlighterScale
    }
}

extension CGPoint {
    func point(forSize size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width, y: self.y * size.height)
    }
}
