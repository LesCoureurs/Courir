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
    static let obstacleSpawnXCoordinate: Int = 32
    static let obstacleSpawnYCoordinate: Int = 5

    let type: ObstacleType
    
    private(set) var xWidth = 2
    private(set) var yWidth = 22
    
    var xCoordinate = Obstacle.obstacleSpawnXCoordinate
    var yCoordinate = Obstacle.obstacleSpawnXCoordinate
    
    init(type: ObstacleType) {
        self.type = type
    }
}