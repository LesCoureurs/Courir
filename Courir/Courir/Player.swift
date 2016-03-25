//
//  Player.swift
//  Courir
//
//  Created by Sebastian Quek on 19/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit

enum PlayerState {
    case Stationary, Running, Invulnerable(Int), Jumping(Int), Ducking(Int)
}

class Player: GameObject {
    static let spawnXCoordinate = 12 * unitsPerGameGridCell
    static let minSpawnYCoordinate = 5 * unitsPerGameGridCell
    static let spawnYCoordinateIncrement = 6 * unitsPerGameGridCell
    
    let playerNumber: Int
    let xWidth = 3 * unitsPerGameGridCell
    let yWidth = 3 * unitsPerGameGridCell
    
    weak var observer: Observer?
    
    var xCoordinate = Player.spawnXCoordinate {
        didSet {
            observer?.didChangeProperty("xCoordinate", from: self)
        }
    }
    
    var yCoordinate: Int {
        didSet {
            observer?.didChangeProperty("yCoordinate", from: self)
        }
    }
    
    var zCoordinate: CGFloat = 0 {
        didSet {
            observer?.didChangeProperty("zCoordinate", from: self)
        }
    }
    
    private(set) var state = PlayerState.Stationary {
        didSet {
            observer?.didChangeProperty("state", from: self)
        }
    }
    
    
    // Range of playerNumber = [0, 3]
    init(playerNumber: Int, isMultiplayer: Bool) {
        assert(0 <= playerNumber && playerNumber <= 3)
        self.playerNumber = playerNumber
        yCoordinate = Player.minSpawnYCoordinate +
            playerNumber * Player.spawnYCoordinateIncrement
        if !isMultiplayer {
            yCoordinate += Int(Player.spawnYCoordinateIncrement/2)
        }
    }
    
    func fallBehind() {
        xCoordinate -= 1 * unitsPerGameGridCell
    }
    
    func run() {
        state = .Running
    }
    
    func jump(startTimeStep: Int) {
        state = .Jumping(startTimeStep)
    }
    
    func duck(startTimeStep: Int) {
        state = .Ducking(startTimeStep)
    }
    
    func becomeInvulnerable(startTimeStep: Int) {
        state = .Invulnerable(startTimeStep)
    }
}