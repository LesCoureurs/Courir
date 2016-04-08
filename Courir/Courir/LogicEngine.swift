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
    
    private(set) var timeStep = 0
    private var lastObstacleTimeStep: Int?
    private var eventQueue = [(event: GameEvent, playerNumber: Int, timeStep: Int,
        otherData: AnyObject?)]()

    init(isMultiplayer: Bool, peers: [MCPeerID], seed: NSData? = nil) {
        obstacleGenerator = ObstacleGenerator(seed: seed)
        state = GameState(seed: obstacleGenerator.seed, isMultiplayer: isMultiplayer)
        state.initPlayers(peers)
    }
    
    convenience init(ghostStore: GhostStore) {
        let ghostID = MCPeerID(displayName: "Ghost Player")
        self.init(isMultiplayer: false, peers: [ghostID], seed: ghostStore.seed)
        let ghostPlayerNumber = state.peerMapping[ghostID]
        state.getPlayer(withPeerID: ghostID)?.ready()
        state.updatePlayerScore(ghostID, score: ghostStore.score)
        initGhostEventQueue(ghostStore.eventSequence, ghostPlayerNumber: ghostPlayerNumber!)
    }
    
    var score: Int {
        return state.distance
    }
    
    var speed: Int {
        return state.currentSpeed
    }
    
    private func initGhostEventQueue(eventSequence: [PlayerEvent], ghostPlayerNumber: Int) {
        let ghostSequence = eventSequence.map {
            (event: $0.event, playerNumber: ghostPlayerNumber, timeStep: $0.timeStep,
                otherData: $0.otherData)
        }
        eventQueue.appendContentsOf(ghostSequence)
        eventQueue.sortInPlace { $0.timeStep > $1.timeStep }
    }
    

    // MARK: Logic Handling
    
    func update() {
        guard !state.gameIsOver else {
            return
        }
        updateEventQueue()
        updateEnvironmentPosition()
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
        
        switch event {
        case .PlayerDidJump, .PlayerDidDuck:
            handlePlayerActionEvent(player, timeStep: occurrence, action: event)
        case .PlayerDidCollide:
            handlePlayerCollisionEvent(player, xCoordinate: data as? Int)
        default:
            break
        }
    }
    
    func handlePlayerActionEvent(player: Player, timeStep occurrence: Int, action: GameEvent) {
        assert (action == .PlayerDidJump || action == .PlayerDidDuck)
        
        if action == .PlayerDidJump {
            player.jump(occurrence)
        } else {
            player.duck(occurrence)
        }
        
        if isValidToSend(player) {
            sendActionData(action)
        }
        
        if player.playerNumber == state.myPlayer.playerNumber {
            switch action {
            case .PlayerDidJump:
                state.addJumpEvent(occurrence)
            case .PlayerDidDuck:
                state.addDuckEvent(occurrence)
            default:
                break
            }
        }
    }
    
    func handlePlayerCollisionEvent(player: Player, xCoordinate: Int?) {
        player.run()
        if player.playerNumber == state.myPlayer.playerNumber {
            player.fallBehind()
            state.addCollideEvent(timeStep, xCoordinate: player.xCoordinate)
            player.becomeInvulnerable(timeStep)
            if isValidToSend(player) {
                sendCollisionData(player.xCoordinate)
            }
            // If player fell off the grid, he finished the race
            if player.xCoordinate < 0 {
                state.updatePlayerScore(myPeerID, score: score)
                player.lost()
                
                if isValidToSend(player) {
                    sendPlayerLostData(score)
                }
                
                checkRaceFinished()
            }
        } else {
            player.xCoordinate = xCoordinate!
        }
    }
    
    // MARK: sending data
    private func isValidToSend(player: Player) -> Bool {
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
    
    private func updateEnvironmentPosition() {
        for environmentObject in state.environmentObjects {
            environmentObject.xCoordinate -= speed
            if environmentObject.xCoordinate < Environment.removalXCoordinate {
                environmentObject.resetXCoordinate()
            }
        }
    }
    
    private func updateObstaclePositions() {
        
        func shouldKeepObstacle(obstacle: Obstacle) -> Bool {
            return obstacle.xCoordinate + obstacle.xWidth - 1 >= Obstacle.removalXCoordinate
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
                    if timeStep - startTimeStep >= jumpTimeSteps {
                        player.run()
                    }
                case let .Ducking(startTimeStep):
                    if timeStep - startTimeStep >= duckTimeSteps {
                        player.run()
                    }
                case let .Invulnerable(startTimeStep):
                    if timeStep - startTimeStep >= invulnerableTimeSteps {
                        player.run()
                    }
                default:
                    continue
            }
        }
    }
    
    private func handleCollisions() {
        guard state.myPlayer.state != .Lost else {
            return
        }
        
        func collisionDidOccur() {
            appendToEventQueue(.PlayerDidCollide, playerNumber: state.myPlayer.playerNumber,
                               occurringTimeStep: timeStep)
        }
        
        let obstaclesInNextFrame = state.obstacles.filter {
            $0.xCoordinate < state.myPlayer.xCoordinate + state.myPlayer.xWidth + speed &&
            $0.xCoordinate + $0.xWidth >= state.myPlayer.xCoordinate
        }
        let nonFloatingObstacles = obstaclesInNextFrame.filter{$0.type == ObstacleType.NonFloating}
        let floatingObstacles = obstaclesInNextFrame.filter{$0.type == ObstacleType.Floating}

        switch state.myPlayer.physicalState {
            case .Jumping(_):
                if floatingObstacles.count > 0 {
                    collisionDidOccur()
                }
            case .Ducking(_):
                if nonFloatingObstacles.count > 0 {
                    collisionDidOccur()
                }
            case .Invulnerable(_), .Stationary:
                return
            case .Running:
                if obstaclesInNextFrame.count > 0 {
                    collisionDidOccur()
                }
        }
    }
    
    private func generateObstacle() {
        func readyForNextObstacle() -> Bool {
            return lastObstacleTimeStep == nil || timeStep > Int(obstacleSpaceMultiplier
                * Double(max(jumpTimeSteps, duckTimeSteps))) + lastObstacleTimeStep!
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
        guard let dataDict = data as? [String: AnyObject],
            score = dataDict["score"] as? Int else {
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