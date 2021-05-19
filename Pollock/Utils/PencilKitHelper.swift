//
//  PencilKitHelper.swift
//  Pollock
//
//  Created by Erik Bye on 5/17/21.
//  Copyright © 2021 Skylar Schipper. All rights reserved.
//

import Foundation

public struct PencilKitHelper {
    public static func isPencilKitSupported() -> Bool {
        if #available(iOS 14.0, *) {
            return true
        } else {
            return false
        }
        
    }
}
