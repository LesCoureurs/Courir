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
    private var eventQueue = [(event: GameEvent, playerNumber: Int, timeStep: Int,
        otherData: AnyObject?)]()
    
    init(playerNumber: Int, seed: String? = nil, isMultiplayer: Bool, peers: [MCPeerID]) {
        obstacleGenerator = ObstacleGenerator(seed: seed)
        let ownPlayer = Player(playerNumber: playerNumber, isMultiplayer: isMultiplayer)
        ownPlayer.ready()
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

    func handleEvent(event: GameEvent, playerNumber: Int?, occurringTimeStep: Int? = nil,
                     otherData data: AnyObject? = nil) {
        guard let player = state.players.filter({ $0.playerNumber == playerNumber }).first else {
            return
        }
        
        var occurrence: Int
        if occurringTimeStep != nil {
            occurrence = occurringTimeStep!
        } else {
            occurrence = timeStep
        }
        
        switch event {
            case .PlayerDidJump:
                player.jump(occurrence)
                if state.isMultiplayer && player.playerNumber == state.myPlayer.playerNumber {
                    sendActionData(.PlayerDidJump)
                }
            case .PlayerDidDuck:
                player.duck(occurrence)
                if state.isMultiplayer && player.playerNumber == state.myPlayer.playerNumber {
                    sendActionData(.PlayerDidDuck)
                }
            case .PlayerDidCollide:
                player.run()
                if player.playerNumber == state.myPlayer.playerNumber {
                    player.fallBehind()
                    player.becomeInvulnerable(timeStep)
                    if state.isMultiplayer {
                        sendCollisionData(player.xCoordinate)
                    }
                    if player.xCoordinate < 0 {
                        delegate?.gameDidEnd(score)
                        state.gameIsOver = true
                    }
                } else {
                    guard let xCoordinate = data as? Int else {
                        break
                    }
                    player.xCoordinate = xCoordinate
                }
            default:
                break
        }
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
            switch player.physicalState {
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
        delegate?.didGenerateObstacle(obstacle)
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
}

// MARK: GameNetworkPortalGameStateDelegate
extension LogicEngine: GameNetworkPortalGameStateDelegate {
    func jumpActionReceived(data: AnyObject?, peer: MCPeerID) {
        guard let playerNumber = state.peerMapping[peer],
            dataDict = data as? [String: AnyObject] else {
            return
        }
        guard let occurringTimeStep = dataDict["time_step"] as? Int else {
            return
        }
        appendToEventQueue(.PlayerDidJump, playerNumber: playerNumber,
                           occurringTimeStep: occurringTimeStep)
    }

    func duckActionReceived(data: AnyObject?, peer: MCPeerID) {
        guard let playerNumber = state.peerMapping[peer],
            dataDict = data as? [String: AnyObject] else {
                return
        }
        guard let occurringTimeStep = dataDict["time_step"] as? Int else {
            return
        }
        appendToEventQueue(.PlayerDidDuck, playerNumber: playerNumber,
                           occurringTimeStep: occurringTimeStep)
    }

    func collideActionReceived(data: AnyObject?, peer: MCPeerID) {
        guard let playerNumber = state.peerMapping[peer],
            dataDict = data as? [String: AnyObject] else {
                return
        }
        guard let occurringTimeStep = dataDict["time_step"] as? Int,
            xCoordinate = dataDict["x_coordinate"] else {
                return
        }
        appendToEventQueue(.PlayerDidCollide, playerNumber: playerNumber,
                           occurringTimeStep: occurringTimeStep, otherData: xCoordinate)
    }
  
    func gameReadySignalReceived(data: AnyObject?, peer: MCPeerID) {
        if let player = gameState.getPlayer(withPeerID: peer) {
            player.ready()
        }
    }

    func gameEndSignalReceived(data: AnyObject?, peer: MCPeerID) {

    }
    
    func disconnectedFromGame() {
        
    }
}