//
//  Comparable.swift
//  Pollock
//
//  Created by Skylar Schipper on 8/23/17.
//  Copyright © 2017 Skylar Schipper. All rights reserved.
//

import Foundation

extension Comparable {
    func clamp(_ bounds: ClosedRange<Self>) -> Self {
        return min(max(bounds.lowerBound, self), bounds.upperBound)
    }
}
