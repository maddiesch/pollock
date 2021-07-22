//
//  CompressorTests.swift
//  Pollock
//
//  Created by Skylar Schipper on 5/11/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import XCTest
@testable import Pollock

class CompressorTests: XCTestCase {
    func testDataCompression() {
        let data = "potenti rutrum erat pellentesque facilisis proin nisi quisque".data(using: .utf8)!

        let compressor = Compressor(data, .deflate)

        do {
            let compressed = try compressor.perform()
            XCTAssert(data.count > compressed.count)
        } catch {
            print(error)
            XCTFail()
        }
    }

    func testDataDecompress() {
        let data = "potenti rutrum erat pellentesque facilisis proin nisi quisque".data(using: .utf8)!

        let compressor = Compressor(data, .deflate)

        do {
            let compressed = try compressor.perform()
            XCTAssert(data.count > compressed.count)

            let output = Compressor(compressed, .infate)
            let out = try output.perform()
            XCTAssertEqual(data, out)
        } catch {
            print(error)
            XCTFail()
        }
    }

    func testZipUnzip() {
        let data = "potenti rutrum erat pellentesque facilisis proin nisi quisque".data(using: .utf8)!

        do {
            let zipped = try data.zip()
            let unzipped = try zipped.unzip(skipChecksumValidate: false)
            XCTAssertEqual(unzipped, data)
        } catch {
            print(error)
            XCTFail()
        }
    }

    func testUnzipLargeFile() {
        let compressed = try! Data(contentsOf: Bundle(for: CompressorTests.self).url(forResource: "decompress-test", withExtension: "txt.zlib")!)
        let uncompressed = try! Data(contentsOf: Bundle(for: CompressorTests.self).url(forResource: "decompress-test", withExtension: "txt")!)

        let unzipped = try! compressed.unzip()

        XCTAssertEqual(uncompressed, unzipped)
    }

    func testZipLargeFile() {
        let compressed = try! Data(contentsOf: Bundle(for: CompressorTests.self).url(forResource: "decompress-test", withExtension: "txt.zlib")!)
        let uncompressed = try! Data(contentsOf: Bundle(for: CompressorTests.self).url(forResource: "decompress-test", withExtension: "txt")!)

        let zipped = try! uncompressed.zip()

        XCTAssertEqual(zipped, compressed)
    }

    func testIsZip() {
        let compressed = try! Data(contentsOf: Bundle(for: CompressorTests.self).url(forResource: "decompress-test", withExtension: "txt.zlib")!)
        let uncompressed = try! Data(contentsOf: Bundle(for: CompressorTests.self).url(forResource: "decompress-test", withExtension: "txt")!)

        XCTAssertTrue(compressed.isZip)
        XCTAssertFalse(uncompressed.isZip)
    }
    
    func testProjectHasEraser() {
        let eraserData = try! Data(contentsOf: (Bundle(for: CompressorTests.self).url(forResource: "eraser_with_two_pen_lines", withExtension: "json")!))
        let project = try! Serializer.unserialize(data: eraserData)
        XCTAssertTrue(project.hasEraserTool)
    }
    
    func testProjectHasNoEraser() {
        let eraserData = try! Data(contentsOf: (Bundle(for: CompressorTests.self).url(forResource: "blue_pen_line", withExtension: "json")!))
        let project = try! Serializer.unserialize(data: eraserData)
        XCTAssertTrue(!project.hasEraserTool)
    }
    
    @available(iOS 14.0, *)
    func testPenWidthConversion() {
        let eraserData = try! Data(contentsOf: (Bundle(for: CompressorTests.self).url(forResource: "blue_pen_line", withExtension: "json")!))
        let project = try! Serializer.unserialize(data: eraserData)
        
        let lineWidthBefore = project.canvas(atIndex: 0).allDrawings.first?.tool.lineWidth

        let json = try! project.serializePK()
        let data = try! JSONSerialization.data(withJSONObject: json, options: [])
        
        let newProject = try! Serializer.unserialize(data: data)
        
        let lineWidthAfter = newProject.canvas(atIndex: 0).allDrawings.first?.tool.lineWidth
        
        XCTAssertTrue(lineWidthBefore!.isEqual(to: lineWidthAfter!))
    }
    
    @available(iOS 14.0, *)
    func testUpscaleDownScale() {
        let eraserData = try! Data(contentsOf: (Bundle(for: CompressorTests.self).url(forResource: "blue_pen_line", withExtension: "json")!))
        let project = try! Serializer.unserialize(data: eraserData)
        
        let lineWidthBefore = project.canvas(atIndex: 0).allDrawings.first?.tool.lineWidth
        
        let canvas = project.canvas(atIndex: 0)
        
        let pkDrawing = canvas.pkdrawing!
        
        let size = CGSize(width: 100, height: 100)
        canvas.canvasSize = size

        let upscaleDrawing = PKDrawingExtractor.upscalePoints(ofDrawing: pkDrawing, withSize: size)
        let downscaleDrawing = PKDrawingExtractor.downscalePoints(ofDrawing: upscaleDrawing, withSize: size)
        
        canvas._pkdrawing = downscaleDrawing
        
        let json = try! project.serializePK()
        let data = try! JSONSerialization.data(withJSONObject: json, options: [])
        
        let newProject = try! Serializer.unserialize(data: data)
        
        let lineWidthAfter = newProject.canvas(atIndex: 0).allDrawings.first?.tool.lineWidth
        
        XCTAssertTrue(lineWidthBefore!.isEqual(to: lineWidthAfter!))
    }
    
    func testSerialize() {
        
        
        
        let jsonString = "{\"location\": \"the moon\"}"

        if let documentDirectory = FileManager.default.urls(for: .documentDirectory,
                                                            in: .userDomainMask).first {
            let pathWithFilename = documentDirectory.appendingPathComponent("myJsonString.json")
            do {
                try jsonString.write(to: pathWithFilename,
                                     atomically: true,
                                     encoding: .utf8)
            } catch {
                // Handle error
            }
        }
        
    
        
        
        
        let json:[String : Any] = ["key": "value"]
        
        let data = try? JSONSerialization.data(withJSONObject: json, options: [])
//
        guard let convertedJSON = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] else {
//            XCTFail()
            return
        }
        if let dict = convertedJSON {
            if let value = dict["key"] as? String {
                XCTAssert(value == "value")
                
            } else {
                XCTFail()
            }
        }
        
        
        
        
            

//        let proj = try Serializer.unserialize(data: data)
//
//        try renderer.load(project: proj)
        
    }
}
