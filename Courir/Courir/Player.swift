//
//  Player.swift
//  Courir
//
//  Created by Sebastian Quek on 19/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit

enum PlayerState {
    case Stationary, Running, Jumping(Int), Ducking(Int)
}

class Player: GameObject {
    static let spawnXCoordinate = 12
    static let minSpawnYCoordinate = 5
    static let spawnYCoordinateIncrement = 6
    
    private(set) var xWidth = 4
    private(set) var yWidth = 4
    
    var xCoordinate = Player.spawnXCoordinate
    var yCoordinate: Int
    
    private(set) var state = PlayerState.Stationary
    
    // Range of playerNumber = [0, 3]
    init(playerNumber: Int) {
        assert(0 <= playerNumber && playerNumber <= 3)
        yCoordinate = Player.minSpawnYCoordinate +
            playerNumber * Player.spawnYCoordinateIncrement
    }
    
    func fallBehind() {
        xCoordinate -= 1
    }
    
    func run() {
        state = .Running
    }
    
    func jump(startDistance: Int) {
        state = .Jumping(startDistance)
    }
    
    func duck(startDistance: Int) {
        state = .Ducking(startDistance)
    }
}