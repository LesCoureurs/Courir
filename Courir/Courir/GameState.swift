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

    var isMultiplayer: Bool
    var gameIsOver = false
    
    init(player: Player, isMultiplayer: Bool = false) {
        self.isMultiplayer = isMultiplayer
        myPlayer = player
        players.append(myPlayer)
    }
    
    var objects: [GameObject] {
        return players.map {$0 as GameObject} + obstacles.map {$0 as GameObject}
    }
}