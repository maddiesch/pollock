//
//  ConverterTests.swift
//  PollockTests
//
//  Created by Erik Bye on 11/9/21.
//  Copyright © 2021 Skylar Schipper. All rights reserved.
//


import XCTest
@testable import Pollock

class DrawingUnitConverterTests: XCTestCase {

    func testConvertPixelToPK() {
        let pixel: CGFloat = 1
        let converted = DrawingUnitConverter.pixelToPK(pixelSize: pixel)
        let pkValue: CGFloat = 2.414285
        XCTAssertEqual(converted, pkValue, accuracy: 0.0000001, "Expected closer")
    }
    
    func testConvertPKToPixel() {
        let pkValue: CGFloat = 2.414285
        let pixel: CGFloat = 1
        let converted = DrawingUnitConverter.pkToPixel(pkSize: pkValue)
        XCTAssertEqual(converted, pixel, accuracy: 0.0000001, "Expected closer")
    }
    
}
