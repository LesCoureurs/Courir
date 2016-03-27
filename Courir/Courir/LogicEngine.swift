//
//  LogicEngine.swift
//  Courir
//
//  Created by Ian Ngiaw on 3/20/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit
import MultipeerConnectivity

protocol LogicEngineDelegate: class {
    func didGenerateObstacle(obstacle: Obstacle)
    func didRemoveObstacle(obstacle: Obstacle)
    func gameDidEnd(score: Int)
}

class LogicEngine {

    // MARK: Properties

    let state: GameState
    private let obstacleGenerator: ObstacleGenerator
    
    weak var delegate: LogicEngineDelegate?

    private let gameNetworkPortal = GameNetworkPortal._instance
    
    private var timeStep = 0
    private var lastObstacleTimeStep: Int?
    private var eventQueue = [(event: GameEvent, playerNumber: Int, timeStep: Int)]()
    
    init(playerNumber: Int, seed: Int? = nil, isMultiplayer: Bool, peers: [MCPeerID]) {
        obstacleGenerator = ObstacleGenerator(seed: seed)
        let ownPlayer = Player(playerNumber: playerNumber, isMultiplayer: isMultiplayer)
        state = GameState(player: ownPlayer, isMultiplayer: isMultiplayer)
        if isMultiplayer {
            state.initPeers(peers)
        }
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

    // MARK: Logic Handling
    
    func update() {
        guard !state.gameIsOver else {
            return
        }
        updateEventQueue()
        updateObstaclePositions()
        handleCollisions()
        updatePlayerStates()
        generateObstacle()
        updateDistance()
        updateGameSpeed(timeStep)
        timeStep += 1
    }

    func handleEvent(event: GameEvent, player: Int?, occurringTimeStep: Int = timeStep) {
        if let player = state.players.filter({ $0.playerNumber == player }).first {
            switch event {
                case .PlayerDidJump:
                    player.jump(occurringTimeStep)
                    if state.isMultiplayer && player! == state.myPlayer.playerNumber {
                        var jumpData = [String: AnyObject]()
                        jumpData["time_step"] = occurringTimeStep
                        gameNetworkPortal.send(.PlayerDidJump, data: jumpData)
                    }
                case .PlayerDidDuck:
                    player.duck(occurringTimeStep)
                    if state.isMultiplayer && player! == state.myPlayer.playerNumber {
                        var duckData = [String: AnyObject]()
                        duckData["time_step"] = occurringTimeStep
                        gameNetworkPortal.send(.PlayerDidJump, data: duckData)
                    }
                default:
                    break
            }
        }
    }
    
    private func updateEventQueue() {
        while eventQueue.last?.timeStep <= timeStep {
            guard let front = eventQueue.popLast() else {
                break
            }
            handleEvent(front.event, player: front.playerNumber, occurringTimeStep: front.timeStep)
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
                delegate?.didRemoveObstacle(obstacle)
            } else {
                obstaclesOnScreen.append(obstacle)
            }
        }
        
        state.obstacles = obstaclesOnScreen
    }
    
    private func updatePlayerStates() {
        for player in state.players {
            switch player.state {
                case let .Jumping(startTimeStep):
                    if timeStep - startTimeStep > jumpTimeSteps {
                        player.run()
                    } else {
                        updateJumpingPlayerPosition(player, startTimeStep)
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
    
    private func updateJumpingPlayerPosition(player: Player, _ startTimeStep: Int) {
        let time = CGFloat(timeStep - startTimeStep)/CGFloat(framerate)
        // using the formula x = x0 + vt + 0.5*at^2
        player.zCoordinate = velocity * time + 0.5 * acceleration * time * time
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
                delegate?.gameDidEnd(score)
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
        default:
            break
        }
    }
    
    private func generateObstacle() {
        func readyForNextObstacle() -> Bool {
            if lastObstacleTimeStep == nil {
                return true
            } else {
                return timeStep > Int(obstacleSpaceMultiplier
                    * Double(max(jumpTimeSteps, duckTimeSteps))) + lastObstacleTimeStep!
            }
        }
        
        if (readyForNextObstacle()) {
            if let obstacle = obstacleGenerator.getNextObstacle() {
                lastObstacleTimeStep = timeStep
                insertObstacle(obstacle)
            }
        }
    }

    private func updateDistance() {
        state.distance += speed
    }

    func updateGameSpeed(timeStep: Int) {
        state.currentSpeed = Int(speedMultiplier * log(Double(timeStep+1))) + initialGameSpeed
    }
    
    private func insertObstacle(obstacle: Obstacle) {
        state.obstacles.append(obstacle)
        delegate?.didGenerateObstacle(obstacle)
    }
    
    private func insertPlayer(player: Player) {
        state.players.append(player)
    }
    
    private func appendToEventQueue(event: GameEvent, playerNumber: Int, occurringTimeStep: Int) {
        eventQueue.append((event: event, playerNumber: playerNumber, timeStep: occurringTimeStep))
        eventQueue.sortInPlace { $0.timeStep > $1.timeStep }
    }
}

// MARK: GameNetworkPortalGameStateDelegate
extension LogicEngine: GameNetworkPortalGameStateDelegate {
    func jumpActionReceived(data: AnyObject, peer: MCPeerID) {
        guard let playerNumber = state.peerMapping[peer],
            dataDict = data as? [String: AnyObject] else {
            return
        }
        guard let timeStepOccurrenceString = dataDict["time_step"] as? String else {
            return
        }
        guard let occurringTimeStep = Int(timeStepOccurrenceString) {
            return
        }
        appendToEventQueue(.PlayerDidJump, playerNumber: playerNumber,
                           occurringTimeStep: occurringTimeStep)
    }

    func duckActionReceived(data: AnyObject, peer: MCPeerID) {
        guard let playerNumber = state.peerMapping[peer],
            dataDict = data as? [String: AnyObject] else {
                return
        }
        guard let timeStepOccurrenceString = dataDict["time_step"] as? String else {
            return
        }
        guard let occurringTimeStep = Int(timeStepOccurrenceString) {
            return
        }
        appendToEventQueue(.PlayerDidDuck, playerNumber: playerNumber,
                           occurringTimeStep: occurringTimeStep)
    }

    func collideActionReceived(data: AnyObject, peer: MCPeerID) {

    }

    func gameStartSignalReceived(data: AnyObject, peer: MCPeerID) {
        if let player = gameState.getPlayer(withPeerID: peer) {
            player.ready()
        }
    }

    func gameEndSignalReceived(data: AnyObject, peer: MCPeerID) {

    }
}