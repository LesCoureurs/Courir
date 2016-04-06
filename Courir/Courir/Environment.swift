//
//  Environment.swift
//  Courir
//
//  Created by Sebastian Quek on 6/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

class Environment: GameObject {
    static let spawnXCoordinate = 32 * unitsPerGameGridCell
    static let spawnYCoordinate = -64 * unitsPerGameGridCell
    
    let xWidth = 64 * unitsPerGameGridCell
    let yWidth = 64 * unitsPerGameGridCell
    
    weak var observer: Observer?
    
    var xCoordinate = Environment.spawnXCoordinate {
        didSet {
            observer?.didChangeProperty("xCoordinate", from: self)
        }
    }
    
    var yCoordinate = Environment.spawnYCoordinate {
        didSet {
            observer?.didChangeProperty("yCoordinate", from: self)
        }
    }
}