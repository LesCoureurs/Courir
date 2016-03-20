//
//  LogicEngine.swift
//  Courir
//
//  Created by Ian Ngiaw on 3/20/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Foundation

class LogicEngine {
    let state = GameState()
    let obstacleGenerator: ObstacleGenerator
    
    init(seed: Int? = nil) {
        obstacleGenerator = ObstacleGenerator(seed: seed)
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
    
    func update() {
        updateObstaclePositions()
        handleCollisions()
        generateObstacle()
    }
    
    private func updateObstaclePositions() {
        for obstacle in state.obstacles {
            obstacle.xCoordinate -= state.currentSpeed
        }
        // Remove obstacles that have gone off-screen
        state.obstacles = state.obstacles.filter{$0.xCoordinate + $0.xWidth - 1 >= 0}
    }
    
    private func handleCollisions() {
        
    }
    
    private func generateObstacle() {
        func readyForNextObstacle() -> Bool {
            return false
        }
        
        if (readyForNextObstacle()) {
            if let obstacle = obstacleGenerator.getNextObstacle() {
                insertObstacle(obstacle)
            }
        }
    }
    
    func updateGameSpeed(timeStep: Int) {
        state.currentSpeed = initialGameSpeed + Int(Double(timeStep) * gameAcceleration)
    }
    
    func insertObstacle(obstacle: Obstacle) {
        state.obstacles.append(obstacle)
    }
    
    func insertPlayer(player: Player) {
        state.players.append(player)
    }
}