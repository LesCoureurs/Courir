//
//  Environment.swift
//  Courir
//
//  Created by Sebastian Quek on 6/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//
import UIKit
class Environment: GameObject {
    static let spawnXCoordinate = 15 * unitsPerGameGridCell // 32
    static let spawnYCoordinate = -66 * unitsPerGameGridCell // -118
    static let spawnXCoordinateIncrement = 66 * unitsPerGameGridCell
    
    let xWidth = 128 * unitsPerGameGridCell
    let yWidth = 96 * unitsPerGameGridCell
    
    weak var observer: Observer?
    var identifier: Int
    
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
    
    var zPosition = -99999 {
        didSet {
            observer?.didChangeProperty("zPosition", from: self)
        }
    }
    
    init(identifier: Int) {
        self.identifier = identifier
        self.zPosition = -99999 + identifier
        xCoordinate = Environment.spawnXCoordinate + identifier * Environment.spawnXCoordinateIncrement
    }
    
    func resetXCoordinate() {
        xCoordinate = Environment.spawnXCoordinate + 2 * Environment.spawnXCoordinateIncrement
        zPosition += 4
    }
}