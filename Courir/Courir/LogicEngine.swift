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
    func didCollide(player: Player)
    func didJump()
    func didDuck()
    func gameDidEnd()
}

class LogicEngine {
    let state: GameState
    let obstacleGenerator: ObstacleGenerator
    
    private var delegate: LogicEngineDelegate!
    var timeStep = 0
    var lastObstacleDistance: Int?
    
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
    
    var jumpDistance: Int {
        return Int(ceil(Double(state.currentSpeed) * jumpDuration)) * unitsPerGameGridCell
    }
    
    var duckDistance: Int {
        return Int(ceil(Double(state.currentSpeed) * duckDuration)) * unitsPerGameGridCell
    }
    
    var invulnerableDistance: Int {
        return Int(ceil(Double(state.currentSpeed) * invulnerableDuration)) * unitsPerGameGridCell
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

    func handleEvent(event: GameEvent, player: Int?) {
        let player = state.players.filter { $0.playerNumber == player }
        switch event {
        case .PlayerDidJump:
            player.first?.jump(state.distance)
        case .PlayerDidDuck:
            player.first?.duck(state.distance)
        default:
            break
        }
    }
    
    private func updateObstaclePositions() {
        var obstaclesOnScreen = [Obstacle]()
        
        func shouldRemoveObstacle(obstacle: Obstacle) -> Bool {
            return obstacle.xCoordinate + obstacle.xWidth - 1 < 0
        }
        
        for obstacle in state.obstacles {
            obstacle.xCoordinate -= state.currentSpeed
            if shouldRemoveObstacle(obstacle) {
                delegate.didRemoveObstacle(obstacle)
            } else {
                obstaclesOnScreen.append(obstacle)
            }
        }
        
        state.obstacles = obstaclesOnScreen
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
                case let .Invulnerable(startDistance):
                    if state.distance - startDistance > invulnerableDistance {
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
        
        func handleCollisionsWith(obstacles: [Obstacle],
                                  hasCollidedWith: (Obstacle) -> Bool) {
            for obstacle in obstacles {
                if hasCollidedWith(obstacle) {
                    state.myPlayer.run()
                    state.myPlayer.fallBehind()
                    state.myPlayer.becomeInvulnerable(state.distance)
                    delegate.didCollide(state.myPlayer)
                }
            }
        }
        
        let obstaclesInNextFrame = state.obstacles.filter {
            $0.xCoordinate < state.myPlayer.xCoordinate + state.myPlayer.xWidth + state.currentSpeed &&
            $0.xCoordinate > state.myPlayer.xCoordinate + state.myPlayer.xWidth
        }
        
        let nonFloatingObstacles = obstaclesInNextFrame.filter {
            $0.type == ObstacleType.NonFloating
        }
        
        let floatingObstacles = obstaclesInNextFrame.filter {
            $0.type == ObstacleType.Floating
        }

        switch state.myPlayer.state {
            case let .Jumping(startDistance):
                handleCollisionsWith(nonFloatingObstacles) { (obstacle) -> Bool in
                    return startDistance + self.jumpDistance < self.state.distance + obstacle.xCoordinate
                }
                handleCollisionsWith(floatingObstacles) { _ in true }
            case let .Ducking(startDistance):
                handleCollisionsWith(floatingObstacles) { (obstacle) -> Bool in
                    return startDistance + self.duckDistance < self.state.distance + obstacle.xCoordinate
                }
                handleCollisionsWith(nonFloatingObstacles) { _ in true }
            case .Invulnerable(_):
                return
            case .Running:
                for _ in obstaclesInNextFrame {
                    state.myPlayer.run()
                    state.myPlayer.fallBehind()
                    state.myPlayer.becomeInvulnerable(state.distance)
                    delegate.didCollide(state.myPlayer)
                }
            default:
                return
        }
    }
    
    private func generateObstacle() {
        func readyForNextObstacle() -> Bool {
            if lastObstacleDistance == nil {
                return true
            } else {
                return state.distance > 2 * max(jumpDistance, duckDistance) + lastObstacleDistance!
            }
        }
        
        if (readyForNextObstacle()) {
            if let obstacle = obstacleGenerator.getNextObstacle() {
                lastObstacleDistance = state.distance
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