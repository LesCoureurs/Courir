//
//  Player.swift
//  Courir
//
//  Created by Sebastian Quek on 19/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit

// Connected: Joined the room, but has not entered the GameScene
// Ready: Player has entered GameScene and/or is in an ongoing game
enum PlayerState {
    case Connected, Ready, Disconnected, Won, Lost
}

enum PhysicalState {
    case Stationary, Running, Invulnerable(Int), Jumping(Int), Ducking(Int)
}


class Player: GameObject {
    static let spawnXCoordinate = 12 * unitsPerGameGridCell
    static let minSpawnYCoordinate = 5 * unitsPerGameGridCell
    static let spawnYCoordinateIncrement = 6 * unitsPerGameGridCell
    static let spawnYOffset = [1: 3 * spawnYCoordinateIncrement / 2,
                               2: spawnYCoordinateIncrement,
                               3: spawnYCoordinateIncrement / 2,
                               4: 0]
    
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
    
    private(set) var physicalState = PhysicalState.Stationary {
        didSet {
            observer?.didChangeProperty("state", from: self)
        }
    }

    private(set) var state = PlayerState.Connected
    
    
    // Range of playerNumber = [0, 3]
    init(playerNumber: Int, isMultiplayer: Bool, numPlayers: Int) {
        // TODO: Positioning for multiplayer mode
        assert(0 <= playerNumber && playerNumber <= 3)
        self.playerNumber = playerNumber
        yCoordinate = Player.minSpawnYCoordinate +
            playerNumber * Player.spawnYCoordinateIncrement
        if let centeringOffset = Player.spawnYOffset[numPlayers] {
            yCoordinate += centeringOffset
        }
    }

    func ready() {
        state = .Ready
    }
    
    func fallBehind() {
        xCoordinate -= 1 * unitsPerGameGridCell
    }
    
    func run() {
        physicalState = .Running
    }
    
    func jump(startTimeStep: Int) {
        physicalState = .Jumping(startTimeStep)
    }
    
    func duck(startTimeStep: Int) {
        physicalState = .Ducking(startTimeStep)
    }
    
    func becomeInvulnerable(startTimeStep: Int) {
        physicalState = .Invulnerable(startTimeStep)
    }
}