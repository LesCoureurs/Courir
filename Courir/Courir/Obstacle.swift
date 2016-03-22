//
//  Obstacle.swift
//  Courir
//
//  Created by Sebastian Quek on 19/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit

enum ObstacleType {
    case NonFloating, Floating
}

class Obstacle: GameObject {
    static var uniqueId = 0
    static let spawnXCoordinate = 31 * unitsPerGameGridCell
    static let spawnYCoordinate = 5 * unitsPerGameGridCell

    let type: ObstacleType
    
    private(set) var xWidth = 1 * unitsPerGameGridCell
    private(set) var yWidth = 21 * unitsPerGameGridCell
    
    var xCoordinate = Obstacle.spawnXCoordinate
    var yCoordinate = Obstacle.spawnYCoordinate

    let identifier: String
    
    init(type: ObstacleType) {
        self.type = type
        self.identifier = String(Obstacle.uniqueId)
        Obstacle.uniqueId += 1
    }
}