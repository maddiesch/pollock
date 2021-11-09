//
//  Converter.swift
//  Pollock
//
//  Created by Erik Bye on 11/9/21.
//  Copyright © 2021 Skylar Schipper. All rights reserved.
//

struct DrawingUnitConverter {
    static func pkToPixel(pkSize: CGFloat) -> CGFloat {
        return (pkSize - 1.9) / 0.514285
    }
    
    static func pixelToPK(pixelSize: CGFloat) -> CGFloat {
        return 0.514285 * pixelSize + 1.9
    }
}
