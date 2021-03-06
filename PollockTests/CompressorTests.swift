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
}
