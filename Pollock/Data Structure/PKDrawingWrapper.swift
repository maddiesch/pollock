//
//  PKDrawingWrapper.swift
//  Pollock
//
//  Created by Erik Bye on 5/19/21.
//  Copyright © 2021 Skylar Schipper. All rights reserved.
//

import Foundation
import PencilKit

class PKDrawingWrapper: NSObject {
    var index: Int = 0
//    var drawing: AnyObject
    
    var _drawing: Any?
    
    @available(iOS 13.0, *)
    var drawing: PKDrawing? {
        return _drawing as? PKDrawing
    }
}
