//
//  String.swift
//  Pollock
//
//  Created by Skylar Schipper on 8/3/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

internal extension String {
    var presence: String? {
        if self.count == 0 {
            return nil
        }
        return self
    }
}
