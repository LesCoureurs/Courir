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

    init(mode: GameMode, peers: [MCPeerID] = [MCPeerID](), seed: NSData? = nil, host: MCPeerID? = nil) {
        obstacleGenerator = ObstacleGenerator(seed: seed)
        state = GameState(seed: obstacleGenerator.seed, mode: mode)
        if let hostID = host {
            state.initPlayers(peers, withHost: hostID)
        } else {
            state.initPlayers(peers)
        }
    }
    
    convenience init(ghostStore: GhostStore) {
        let ghostID = MCPeerID(displayName: "Ghost Player")
        self.init(mode: .SinglePlayer, peers: [ghostID], seed: ghostStore.seed)
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
            print("game is over")
            return
        }
        updateEventQueue()
        updateObstaclePositions()
        handleCollisions()
        updatePlayerStates()
        if state.mode != .SpecialMultiplayer {
            generateObstacle()
        }
        updateDistance()
        updateGameSpeed(timeStep)
        timeStep += 1
    }

    func handleEvent(event: GameEvent, playerNumber: Int?, occurringTimeStep: Int? = nil,
                     otherData data: AnyObject? = nil) {
        guard let player = state.getPlayer(withPlayerNumber: playerNumber) else {
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
        case .FloatingObstacleGenerated:
            generateObstacle(.Floating)
            if isValidToSend(player) {
                sendActionData(.FloatingObstacleGenerated)
            }
        case .NonFloatingObstacleGenerated:
            generateObstacle(.NonFloating)
            if isValidToSend(player) {
                sendActionData(.NonFloatingObstacleGenerated)
            }
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
        let validToSend = isValidToSend(player)
        
        if player.playerNumber == state.myPlayer.playerNumber {
            player.fallBehind()
            state.addCollideEvent(timeStep, xCoordinate: player.xCoordinate)
            player.becomeInvulnerable(timeStep)
            if validToSend {
                sendCollisionData(player.xCoordinate)
            }
            // If player fell off the grid, he finished the race
            if player.xCoordinate < 0 {
                state.updatePlayerScore(myPeerID, score: score)
                
                if validToSend {
                    sendPlayerLostData(score)
                }
                
                player.lost()

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

    private func readyForNextObstacle() -> Bool {
        return lastObstacleTimeStep == nil || timeStep > Int(obstacleSpaceMultiplier
            * Double(max(jumpTimeSteps, duckTimeSteps))) + lastObstacleTimeStep!
    }

    private func generateObstacle(type: ObstacleType? = nil) {
        if let obstacle = obstacleGenerator.getNextObstacle(type) where readyForNextObstacle() {
            lastObstacleTimeStep = timeStep
            insertObstacle(obstacle)
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
    
    func appendToEventQueue(event: GameEvent, playerNumber: Int, occurringTimeStep: Int, otherData: AnyObject? = nil) {
        eventQueue.append((event: event, playerNumber: playerNumber, timeStep: occurringTimeStep,
            otherData: otherData))
        eventQueue.sortInPlace { $0.timeStep > $1.timeStep }
    }
    
    private func checkRaceFinished() {
        if state.everyoneFinished() {
            print("everyone finished")
            // Stop the update() method
            state.gameIsOver = true
            
            if state.isMultiplayer {
                // Send game end signal
                gameNetworkPortal.send(.GameDidEnd)
            }
        }
    }
}