//
//  Environment.swift
//  Courir
//
//  Created by Sebastian Quek on 6/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//
import UIKit
class Environment: GameObject {
    
    // ==============================================
    // Static constants & variables
    // ==============================================
    
    static let spawnXCoordinate = 15 * unitsPerGameGridCell
    static let spawnYCoordinate = -66 * unitsPerGameGridCell
    static let spawnXCoordinateIncrement = 65 * unitsPerGameGridCell
    static let removalXCoordinate = -40 * unitsPerGameGridCell
    static let lowestZPosition: CGFloat = -99999
    
    static var numEnvironmentObjects = 0
    static var lastObjectXCoordinate: Int {
        return Environment.spawnXCoordinate
             + (Environment.numEnvironmentObjects - 1)
             * Environment.spawnXCoordinateIncrement
    }
    
    // ==============================================
    // Instance variables and methods
    // ==============================================
    
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
    
    var zPosition = Environment.lowestZPosition {
        didSet {
            observer?.didChangeProperty("zPosition", from: self)
        }
    }
    
    init(identifier: Int) {
        self.identifier = identifier
        zPosition = Environment.lowestZPosition + CGFloat(identifier)
        xCoordinate = Environment.spawnXCoordinate + identifier * Environment.spawnXCoordinateIncrement
        Environment.numEnvironmentObjects += 1
    }
    
    deinit {
        Environment.numEnvironmentObjects -= 1
    }
    
    func resetXCoordinate(farthestXCoordinate: Int) {
        xCoordinate = farthestXCoordinate + Environment.spawnXCoordinateIncrement
        zPosition += CGFloat(Environment.numEnvironmentObjects)
    }
}