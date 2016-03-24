//
//  LogicEngine.swift
//  Courir
//
//  Created by Ian Ngiaw on 3/20/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Foundation

protocol LogicEngineDelegate {
    func didGenerateObstacle(obstacle: Obstacle)
    func didRemoveObstacle(obstacle: Obstacle)
    func gameDidEnd(score: Int)
}

class LogicEngine {
    let state: GameState
    let obstacleGenerator: ObstacleGenerator
    
    private var delegate: LogicEngineDelegate!
    var timeStep = 0
    var lastObstacleTimeStep: Int?
    
    init(playerNumber: Int, seed: Int? = nil) {
        obstacleGenerator = ObstacleGenerator(seed: seed)
        let ownPlayer = Player(playerNumber: playerNumber)
        state = GameState(player: ownPlayer)
    }

    func setDelegate(delegate: LogicEngineDelegate) {
        self.delegate = delegate
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
        if state.gameIsOver {
            return
        }
        updateObstaclePositions()
        handleCollisions()
        updatePlayerStates()
        generateObstacle()
        updateDistance()
        updateGameSpeed(timeStep)
        timeStep += 1
    }

    func handleEvent(event: GameEvent, player: Int?) {
        if let player = state.players.filter({ $0.playerNumber == player }).first {
            switch event {
                case .PlayerDidJump:
                    player.jump(timeStep)
                case .PlayerDidDuck:
                    player.duck(timeStep)
                default:
                    break
            }
        }
    }
    
    private func updateObstaclePositions() {
        var obstaclesOnScreen = [Obstacle]()
        
        func shouldRemoveObstacle(obstacle: Obstacle) -> Bool {
            return obstacle.xCoordinate + obstacle.xWidth - 1 < 0
        }
        
        for obstacle in state.obstacles {
            obstacle.xCoordinate -= speed
            if shouldRemoveObstacle(obstacle) {
                delegate.didRemoveObstacle(obstacle)
            } else {
                obstaclesOnScreen.append(obstacle)
            }
        }
        
        state.obstacles = obstaclesOnScreen
    }
    
    private func updateDistance() {
        state.distance += speed
    }
    
    private func updatePlayerStates() {
        for player in state.players {
            switch player.state {
                case let .Jumping(startTimeStep):
                    if timeStep - startTimeStep > jumpTimeSteps {
                        player.run()
                    }
                case let .Ducking(startTimeStep):
                    if timeStep - startTimeStep > duckTimeSteps {
                        player.run()
                    }
                case let .Invulnerable(startTimeStep):
                    if timeStep - startTimeStep > invulnerableTimeSteps {
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
        
        func collisionOccurred() {
            state.myPlayer.run()
            state.myPlayer.fallBehind()
            state.myPlayer.becomeInvulnerable(timeStep)
            if state.myPlayer.xCoordinate < 0 {
                delegate.gameDidEnd(score)
                state.gameIsOver = true
            }
        }
        
        let obstaclesInNextFrame = state.obstacles.filter {
            $0.xCoordinate < state.myPlayer.xCoordinate + state.myPlayer.xWidth + speed &&
            $0.xCoordinate + $0.xWidth >= state.myPlayer.xCoordinate
        }
        
        let nonFloatingObstacles = obstaclesInNextFrame.filter {
            $0.type == ObstacleType.NonFloating
        }
        
        let floatingObstacles = obstaclesInNextFrame.filter {
            $0.type == ObstacleType.Floating
        }

        switch state.myPlayer.state {
            case .Jumping(_):
                if floatingObstacles.count > 0 {
                    collisionOccurred()
                }
            case .Ducking(_):
                if nonFloatingObstacles.count > 0 {
                    collisionOccurred()
                }
            case .Invulnerable(_), .Stationary:
                return
            case .Running:
                if obstaclesInNextFrame.count > 0 {
                    collisionOccurred()
                }
        }
    }
    
    private func generateObstacle() {
        func readyForNextObstacle() -> Bool {
            if lastObstacleTimeStep == nil {
                return true
            } else {
                return timeStep > 2 * max(jumpTimeSteps, duckTimeSteps) + lastObstacleTimeStep!
            }
        }
        
        if (readyForNextObstacle()) {
            if let obstacle = obstacleGenerator.getNextObstacle() {
                lastObstacleTimeStep = timeStep
                insertObstacle(obstacle)
            }
        }
    }
    
    func updateGameSpeed(timeStep: Int) {
        state.currentSpeed = Int(speedMultiplier * log(Double(timeStep+1))) + initialGameSpeed
    }
    
    func insertObstacle(obstacle: Obstacle) {
        state.obstacles.append(obstacle)
        delegate.didGenerateObstacle(obstacle)
    }
    
    func insertPlayer(player: Player) {
        state.players.append(player)
    }
}