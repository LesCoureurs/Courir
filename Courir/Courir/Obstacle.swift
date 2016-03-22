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
    static let spawnXCoordinate = 31
    static let spawnYCoordinate = 5

    let type: ObstacleType
    
    private(set) var xWidth = 2
    private(set) var yWidth = 22
    
    var xCoordinate = Obstacle.spawnXCoordinate
    var yCoordinate = Obstacle.spawnYCoordinate

    let identifier: String
    
    init(type: ObstacleType) {
        self.type = type
        self.identifier = String(Obstacle.uniqueId++)
    }
}