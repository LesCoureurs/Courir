//
//  LogicEngine.swift
//  Courir
//
//  Created by Ian Ngiaw on 3/20/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class LogicEngine {

    // MARK: Properties

    let state: GameState
    private let obstacleGenerator: ObstacleGenerator
    
    private let gameNetworkPortal = GameNetworkPortal._instance
    
    private var timeStep = 0
    private var lastObstacleTimeStep: Int?
    private var eventQueue = [(event: GameEvent, playerNumber: Int, timeStep: Int,
        otherData: AnyObject?)]()

    init(seed: String? = nil, isMultiplayer: Bool, peers: [MCPeerID]) {
        obstacleGenerator = ObstacleGenerator(seed: seed)
        state = GameState(isMultiplayer: isMultiplayer)
        state.initPlayers(peers)
    }
    
    var score: Int {
        return state.distance
    }
    
    var speed: Int {
        return state.currentSpeed
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

    func handleEvent(event: GameEvent, playerNumber: Int?, occurringTimeStep: Int? = nil,
                     otherData data: AnyObject? = nil) {
        guard let player = state.players.filter({ $0.playerNumber == playerNumber }).first else {
            return
        }
        
        var occurrence = timeStep
        if occurringTimeStep != nil {
            occurrence = occurringTimeStep!
        }
        
        let canSend = validToSend(player)
        switch event {
            case .PlayerDidJump:
                player.jump(occurrence)
                if canSend {
                    sendActionData(.PlayerDidJump)
                }
            case .PlayerDidDuck:
                player.duck(occurrence)
                if canSend {
                    sendActionData(.PlayerDidDuck)
                }
            case .PlayerDidCollide:
                handlePlayerCollisionEvent(player, xCoordinate: data as? Int)
            default:
                break
        }
    }
    
    func handlePlayerCollisionEvent(player: Player, xCoordinate: Int?) {
        player.run()
        if player.playerNumber == state.myPlayer.playerNumber {
            player.fallBehind()
            player.becomeInvulnerable(timeStep)
            if validToSend(player) {
                sendCollisionData(player.xCoordinate)
            }
            // If player fell off the grid, he finished the race
            if player.xCoordinate < 0 {
                state.updatePlayerScore(myPeerID, score: score)
                player.lost()
                
                if validToSend(player) {
                    sendPlayerLostData(score)
                }
                
                checkRaceFinished()
            }
        } else {
            player.xCoordinate = xCoordinate!
        }
    }
    
    // MARK: sending data
    private func validToSend(player: Player) -> Bool {
        return state.isMultiplayer
            && player.playerNumber == state.myPlayer.playerNumber
            && state.ownPlayerStillPlaying()
    }
    
    private func sendActionData(event: GameEvent) {
        var actionData = [String: AnyObject]()
        actionData["time_step"] = timeStep
        gameNetworkPortal.send(event, data: actionData)
    }
    
    private func sendCollisionData(xCoordinate: Int) {
        var collisionData = [String: AnyObject]()
        collisionData["time_step"] = timeStep
        collisionData["x_coordinate"] = xCoordinate
        gameNetworkPortal.send(.PlayerDidCollide, data: collisionData)
    }
    
    private func sendPlayerLostData(score: Int) {
        var playerLostData = [String: AnyObject]()
        playerLostData["score"] = score
        gameNetworkPortal.send(.PlayerLost, data: playerLostData)
    }
    
    // MARK: Internal update methods
    private func updateEventQueue() {
        while eventQueue.last?.timeStep <= timeStep {
            guard let front = eventQueue.popLast() else {
                break
            }
            handleEvent(front.event, playerNumber: front.playerNumber,
                        occurringTimeStep: front.timeStep, otherData: front.otherData)
        }
    }
    
    private func updateObstaclePositions() {
        
        func shouldKeepObstacle(obstacle: Obstacle) -> Bool {
            return obstacle.xCoordinate + obstacle.xWidth - 1 >= 0
        }
        
        for obstacle in state.obstacles {
            obstacle.xCoordinate -= speed
        }
        
        state.obstacles = state.obstacles.filter {shouldKeepObstacle($0)}
    }
    
    private func updatePlayerStates() {
        for player in state.players {
            switch player.physicalState {
                case .Stationary:
                    player.run()
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
        guard state.myPlayer.state != .Lost else {
            return
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

        switch state.myPlayer.physicalState {
        case .Jumping(_):
            if floatingObstacles.count > 0 {
                appendToEventQueue(.PlayerDidCollide, playerNumber: state.myPlayer.playerNumber,
                                   occurringTimeStep: timeStep)
            }
        case .Ducking(_):
            if nonFloatingObstacles.count > 0 {
                appendToEventQueue(.PlayerDidCollide, playerNumber: state.myPlayer.playerNumber,
                                   occurringTimeStep: timeStep)
            }
        case .Invulnerable(_), .Stationary:
            return
        case .Running:
            if obstaclesInNextFrame.count > 0 {
                appendToEventQueue(.PlayerDidCollide, playerNumber: state.myPlayer.playerNumber,
                                   occurringTimeStep: timeStep)
            }
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
    }
    
    private func insertPlayer(player: Player) {
        state.players.append(player)
    }
    
    private func appendToEventQueue(event: GameEvent, playerNumber: Int, occurringTimeStep: Int,
                                    otherData: AnyObject? = nil) {
        eventQueue.append((event: event, playerNumber: playerNumber, timeStep: occurringTimeStep,
            otherData: otherData))
        eventQueue.sortInPlace { $0.timeStep > $1.timeStep }
    }
    
    private func checkRaceFinished() {
        if state.everyoneFinished() {
            // Stop the update() method
            state.gameIsOver = true
            
            if state.isMultiplayer {
                // Send game end signal
                gameNetworkPortal.send(.GameDidEnd)
            }
        }
    }
}

// MARK: GameNetworkPortalGameStateDelegate
extension LogicEngine: GameNetworkPortalGameStateDelegate {
    func jumpActionReceived(data: AnyObject?, peer: MCPeerID) {
        handlePlayerAction(.PlayerDidJump, data: data, peer: peer)
    }

    func duckActionReceived(data: AnyObject?, peer: MCPeerID) {
        handlePlayerAction(.PlayerDidDuck, data: data, peer: peer)
    }
    
    private func handlePlayerAction(action: GameEvent, data: AnyObject?, peer: MCPeerID) {
        guard let playerNumber = state.peerMapping[peer],
            dataDict = data as? [String: AnyObject],
            occurringTimeStep = dataDict["time_step"] as? Int else {
                return
        }
        appendToEventQueue(action, playerNumber: playerNumber, occurringTimeStep: occurringTimeStep)
    }

    func collideActionReceived(data: AnyObject?, peer: MCPeerID) {
        guard let playerNumber = state.peerMapping[peer],
            dataDict = data as? [String: AnyObject],
            occurringTimeStep = dataDict["time_step"] as? Int,
            xCoordinate = dataDict["x_coordinate"] else {
                return
        }
        appendToEventQueue(.PlayerDidCollide, playerNumber: playerNumber,
                           occurringTimeStep: occurringTimeStep, otherData: xCoordinate)
    }
  
    func gameReadySignalReceived(data: AnyObject?, peer: MCPeerID) {
        if let player = state.getPlayer(withPeerID: peer) {
            player.ready()
        }
    }

    func playerLostSignalReceived(data: AnyObject?, peer: MCPeerID) {
        guard let dataDict = data as? [String: AnyObject] else {
            return
        }
        
        guard let score = dataDict["score"] as? Int else {
            return
        }
        
        state.updatePlayerScore(peer, score: score)
        state.getPlayer(withPeerID: peer)!.lost()
    }
    
    func gameEndSignalReceived(data: AnyObject?, peer: MCPeerID) {
        // Stop the update() method
        state.gameIsOver = true
    }
    
    func disconnectedFromGame() {
        
    }
}