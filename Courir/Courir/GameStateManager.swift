//
//  GameStateManager.swift
//  Courir
//
//  Created by Ian Ngiaw on 3/20/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Foundation

class GameStateManager {
    let state = GameState()
    
    func updateGameSpeed(timeStep: Int) {
        state.currentSpeed = initialGameSpeed + Int(Double(timeStep) * gameAcceleration)
    }
    
    func updateObstaclePositions() {
        for obstacle in state.obstacles {
            obstacle.xCoordinate -= state.currentSpeed
        }
        // Remove obstacles that have gone off-screen
        state.obstacles = state.obstacles.filter{$0.xCoordinate + $0.xWidth - 1 >= 0}
    }
    
    func insertObstacle(obstacle: Obstacle) {
        state.obstacles.append(obstacle)
    }
    
    func insertPlayer(player: Player) {
        state.players.append(player)
    }
    
    var score: Int {
        return state.distance
    }
    
    var speed: Int {
        return state.currentSpeed
    }
    
    var gameState: GameState {
        return state
    }
}