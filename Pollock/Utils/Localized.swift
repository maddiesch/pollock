//
//  Localized.swift
//  Pollock
//
//  Created by Skylar Schipper on 9/1/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

internal func Localized(_ key: String) -> String {
    return NSLocalizedString(key, tableName: nil, bundle: Bundle(for: DrawingView.self), comment: "Localized String")
}
