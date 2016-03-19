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
    static let defaultHeight = 128
    static let defaultWidth = 32
    static let obstacleSpawnXCoordinate: CGFloat = 700
    static let obstacleSpawnYCoordinate: CGFloat = 100

    let type: ObstacleType
    
    private(set) var height = Obstacle.defaultHeight
    private(set) var width = Obstacle.defaultWidth
    
    var xCoordinate = Obstacle.obstacleSpawnXCoordinate
    var yCoordinate = Obstacle.obstacleSpawnXCoordinate
    
    init(type: ObstacleType) {
        self.type = type
    }
}