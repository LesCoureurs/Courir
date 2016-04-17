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
    /// GCD dispatch source that runs LogicEngine in the background
    private var dispatchTimer: dispatch_source_t?
    
    let state: GameState
    private let obstacleGenerator: ObstacleGenerator
    
    private let gameNetworkPortal = GameNetworkPortal._instance
    
    private var timeStep = 0
    private var lastObstacleTimeStep: Int?
    private var eventQueue = EventQueue()

    init(mode: GameMode, peers: [MCPeerID] = [MCPeerID](), seed: NSData? = nil, host: MCPeerID? = nil) {
        obstacleGenerator = ObstacleGenerator(seed: seed)
        state = GameState(seed: obstacleGenerator.seed, mode: mode)
        if let hostID = host where mode == .SpecialMultiplayer {
            state.initPlayers(peers, withHost: hostID)
        } else {
            state.initPlayers(peers)
        }
    }
    
    /// Convenience initializer to create a `LogicEngine` for when playing with a ghost
    convenience init(ghostStore: GhostStore) {
        let ghostID = MCPeerID(displayName: "Ghost Player")
        self.init(mode: .SinglePlayer, peers: [ghostID], seed: ghostStore.seed)
        let ghostPlayerNumber = state.peerMapping[ghostID]
        let ghostPlayer = state.getPlayer(withPeerID: ghostID)!
        ghostPlayer.ready()
        state.updatePlayerScore(ghostPlayer, score: ghostStore.score)
        initGhostEventQueue(ghostStore.eventSequence, ghostPlayerNumber: ghostPlayerNumber!)
    }
    
    /// The current score
    var score: Int {
        return state.distance
    }
    
    /// The current speed
    var speed: Int {
        return state.currentSpeed
    }
    
    /// Initializes the `eventQueue` with the `eventSequence` saved in a `GhostStore`
    private func initGhostEventQueue(eventSequence: [PlayerEvent], ghostPlayerNumber: Int) {
        let ghostSequence = eventSequence.map {
            (event: $0.event, playerNumber: ghostPlayerNumber, timeStep: $0.timeStep,
                otherData: $0.otherData)
        }
        eventQueue = EventQueue(initialEvents: ghostSequence)
    }
    

    // MARK: Logic Handling
    
    /// Starts `LogicEngine`'s `dispatchTimer`
    func startTick() {
        stopTick()
        dispatchTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0))
        
        dispatch_source_set_timer(dispatchTimer!, dispatch_walltime(nil, 0), NSEC_PER_SEC / 30, NSEC_PER_SEC / 60)
        dispatch_source_set_event_handler(dispatchTimer!, update)
        dispatch_resume(dispatchTimer!)
    }
    
    /// Stops `LogicEngine`'s `dispatchTimer`
    func stopTick() {
        if let timer = dispatchTimer {
            dispatch_source_cancel(timer)
            dispatchTimer = nil
        }
    }
    
    /// Updates the current `state` based on the properties of players and obstacles in the game
    @objc func update() {
        guard !state.gameIsOver else {
            // Stop updating when game is over
            stopTick()
            return
        }
        updateEventQueue()
        updateEnvironmentPosition()
        updateObstaclePositions()
        updateLoserPositions()
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
        case .PlayerLost:
            guard let score = data as? Int else {
                break
            }
            handlePlayerLostEvent(player, timeStep: occurrence, score: score)
        default:
            break
        }
    }
    
    /// Handles `PlayerDidJump` and `PlayerDidDuck` `GameEvent`s
    func handlePlayerActionEvent(player: Player, timeStep occurrence: Int, action: GameEvent) {
        assert (action == .PlayerDidJump || action == .PlayerDidDuck)
        
        guard !player.isJumpingOrDucking() else {
            return
        }
        
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
    
    /// Handles `PlayerLost` `GameEvent`s
    func handlePlayerLostEvent(player: Player, timeStep occurrence: Int, score: Int) {
        if isValidToSend(player) {
            sendPlayerLostData(occurrence, score: score)
        }
        
        state.updatePlayerScore(player, score: score)
        player.lost()
        
        let isSinglePlayerEndable = !state.isMultiplayer && player.playerNumber == state.myPlayer.playerNumber
        let isMultiPlayerEndable = state.isMultiplayer && state.everyoneFinished()
        if isSinglePlayerEndable || isMultiPlayerEndable {
            state.gameIsOver = true
        }
    }
    
    /// Handles `PlayerDidCollide` `GameEvent`s
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
                appendToEventQueue(.PlayerLost, playerNumber: player.playerNumber,
                                   occurringTimeStep: timeStep, otherData: state.distance)
                state.addLostEvent(timeStep, score: state.distance)
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
    
    /// Sends on `gameNetworkPortal` that the player has lost at the current timeStep and score
    func sendPlayerLostData() {
        sendPlayerLostData(timeStep, score: state.distance)
    }
    
    private func sendPlayerLostData(timeStep: Int, score: Int) {
        var playerLostData = [String: AnyObject]()
        playerLostData["time_step"] = timeStep
        playerLostData["score"] = score
        gameNetworkPortal.send(.PlayerLost, data: playerLostData)
    }
    
    // MARK: Internal update methods
    private func updateEventQueue() {
        while eventQueue.head?.timeStep <= timeStep {
            guard let front = eventQueue.removeHead() else {
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
    
    private func updateLoserPositions() {
        for loser in state.players.filter({$0.state == PlayerState.Lost}) {
            loser.xCoordinate -= speed
        }
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

    /// Updates the `state`'s `currentSpeed` to the next `timeStep`'s speed
    func updateGameSpeed(timeStep: Int) {
        state.currentSpeed = Int(speedMultiplier * log(Double(timeStep+1))) + initialGameSpeed
    }
    
    private func insertObstacle(obstacle: Obstacle) {
        state.obstacles.append(obstacle)
    }
    
    private func insertPlayer(player: Player) {
        state.players.append(player)
    }
    
    /// Appends the `GameEvent` to the `eventQueue`
    func appendToEventQueue(event: GameEvent, playerNumber: Int, occurringTimeStep: Int, otherData: AnyObject? = nil) {
        eventQueue.insert(event, playerNumber: playerNumber, timeStep: occurringTimeStep,
                          otherData: otherData)
    }
}