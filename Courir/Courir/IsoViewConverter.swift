//
//  IsoViewConverter.swift
//  Courir
//
//  Created by Sebastian Quek on 6/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit

class IsoViewConverter {
    
    // Used to convert object's coordinates to coordinates in the actual larger grid
    static private let multiple = Double(32 / unitsPerGameGridCell) / 2
    
    /// Convert world coordinates of object to screen coordinates
    static func calculateRenderPositionFor(object: GameObject) -> CGPoint {
        let x = CGFloat(Double(object.xCoordinate) * multiple)
        let y = CGFloat(Double(object.yCoordinate) * multiple)
        
        return pointToIso(CGPointMake(x, y))
    }
    
    static func calculateRenderPositionFor(x: Int, _ y: Int) -> CGPoint {
        let x = CGFloat(Double(x) * multiple)
        let y = CGFloat(Double(y) * multiple)
        
        return pointToIso(CGPointMake(x, y))
    }
    
    /// Convert point to respective screen coordinate in an isometric projection
    static func pointToIso(p: CGPoint) -> CGPoint {
        return CGPointMake(p.x + p.y, (p.y - p.x) / 2)
    }
}