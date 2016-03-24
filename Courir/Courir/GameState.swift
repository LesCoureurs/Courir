//
//  GameState.swift
//  Courir
//
//  Created by Ian Ngiaw on 3/20/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Foundation

class GameState {
    var myPlayer: Player
    var players = [Player]()
    var obstacles = [Obstacle]()
    var currentSpeed = initialGameSpeed
    var distance = 0 // Score

    var gameIsOver = false
    
    init(player: Player) {
        myPlayer = player
        players.append(myPlayer)
    }
    
    var objects: [GameObject] {
        return (players as [GameObject]) + (obstacles as [GameObject])
    }
}