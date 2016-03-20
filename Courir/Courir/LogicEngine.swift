//
//  LogicEngine.swift
//  Courir
//
//  Created by Ian Ngiaw on 3/20/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Foundation

class LogicEngine {
    let state: GameState
    let obstacleGenerator: ObstacleGenerator
    var timeStep = 0
    
    init(playerNumber: Int, seed: Int? = nil) {
        obstacleGenerator = ObstacleGenerator(seed: seed)
        let ownPlayer = Player(playerNumber: playerNumber)
        state = GameState(player: ownPlayer)
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
        updatePlayerStates()
        generateObstacle()
        updateDistance()
        updateGameSpeed(timeStep)
        timeStep += 1
    }
    
    private func updateObstaclePositions() {
        for obstacle in state.obstacles {
            obstacle.xCoordinate -= state.currentSpeed
        }
        // Remove obstacles that have gone off-screen
        state.obstacles = state.obstacles.filter{$0.xCoordinate + $0.xWidth - 1 >= 0}
    }
    
    private func updateDistance() {
        state.distance += state.currentSpeed
    }
    
    private func updatePlayerStates() {
        for player in state.players {
            switch player.state {
                case let .Jumping(startDistance):
                    if state.distance - startDistance > jumpDistance {
                        player.run()
                    }
                case let .Ducking(startDistance):
                    if state.distance - startDistance > duckDistance {
                        player.run()
                    }
                default:
                    continue
            }
        }
    }
    
    private func handleCollisions() {
        // Use state.currentSpeed to check if there are any obstacles
        // within 1 frame of hitting state.myPlayer. If so then
        // state.myPlayer has been hit
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