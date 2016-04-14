//
//  GameState.swift
//  Courir
//
//  Created by Ian Ngiaw on 3/20/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class GameState: Observed {
    
    var environmentObjects = [Environment]()
    
    var myPlayer: Player!
    var players = [Player]()

    var host: Player?
    var hostID: MCPeerID?

    var peerMapping = [MCPeerID: Int]()
    var scoreTracking = [MCPeerID: Int]()
    
    private(set) var myEvents = [PlayerEvent]()

    var obstacles = [Obstacle]() {
        didSet {
            observer?.didChangeProperty("obstacles", from: self)
        }
    }
    
    var currentSpeed = initialGameSpeed
    var distance = 0 {
        didSet {
            observer?.didChangeProperty("distance", from: self)
        }
    } // Score

    private (set) var mode: GameMode
    var isMultiplayer: Bool {
        return mode == .Multiplayer || mode == .SpecialMultiplayer
    }

    let seed: NSData
    var gameIsOver = false {
        didSet {
            observer?.didChangeProperty("gameIsOver", from: self)
        }
    }
    
    weak var observer: Observer?

    init(seed: NSData, mode: GameMode = .SinglePlayer) {
        self.mode = mode
        self.seed = seed
        for i in 0..<numEnvironmentObjects {
            environmentObjects.append(Environment(identifier: i))
        }
    }

    var objects: [GameObject] {
        return players.map {$0 as GameObject} + obstacles.map {$0 as GameObject}
    }

    var allPlayersReady: Bool {
        return players.filter { $0.state == PlayerState.Ready }.count == players.count
    }
    
    var ghostStore: GhostStore {
        return GhostStore(seed: seed, score: distance, eventSequence: myEvents)
    }

    func initPlayers(peers: [MCPeerID]) {
        var allPeerIDs = peers

        allPeerIDs.append(myPeerID)
        allPeerIDs.sortInPlace({ (this, other) in this.displayName < other.displayName })

        initPlayersHelper(allPeerIDs)

    }

    func initPlayers(peers: [MCPeerID], withHost hostID: MCPeerID) {
        var allPeerIDs = Array(Set(peers).union([myPeerID]).subtract([hostID]))
        allPeerIDs.sortInPlace({ (this, other) in this.displayName < other.displayName })

        initPlayersHelper(allPeerIDs)

        self.host = Player(playerNumber: defaultHostNumber, numPlayers: allPeerIDs.count)
        self.hostID = hostID

        if myPeerID == hostID {
            myPlayer = self.host
        }
    }

    private func initPlayersHelper(peers: [MCPeerID]) {
        for (playerNum, peer) in peers.enumerate() {
            let player = Player(playerNumber: playerNum, numPlayers: peers.count)
            if peer == myPeerID {
                myPlayer = player
                player.ready()
            }
            peerMapping[peer] = playerNum
            players.append(player)
        }
    }

    func getPlayer(withPeerID peerID: MCPeerID) -> Player? {
        guard peerID != hostID else {
            return nil
        }

        if let index = peerMapping[peerID] {
            return players[index]
        }
        return nil
    }

    func getPlayer(withPlayerNumber playerNumber: Int?) -> Player? {
        if let player = players.filter({ $0.playerNumber == playerNumber }).first {
            return player
        } else if let host = host where playerNumber == defaultHostNumber {
            return host
        }
        return nil
    }
    
    func everyoneFinished() -> Bool {
        for player in players {
            if player.state != .Lost {
                return false
            }
        }
        return true
    }
    
    func ownPlayerStillPlaying() -> Bool {
        return myPlayer.state != PlayerState.Lost
    }
    
    func updatePlayerScore(player: Player, score: Int) {
        for (peerID, playerNumber) in peerMapping {
            if playerNumber == player.playerNumber {
                scoreTracking[peerID] = score
                break
            }
        }
    }
    
    // MARK: Player event methods
    
    func addJumpEvent(timeStep: Int) {
        addGameEvent(.PlayerDidJump, timeStep: timeStep)
    }
    
    func addDuckEvent(timeStep: Int) {
        addGameEvent(.PlayerDidDuck, timeStep: timeStep)
    }
    
    func addCollideEvent(timeStep: Int, xCoordinate: Int) {
        addGameEvent(.PlayerDidCollide, timeStep: timeStep, otherData: xCoordinate)
    }
    
    func addLostEvent(timeStep: Int, score: Int) {
        addGameEvent(.PlayerLost, timeStep: timeStep, otherData: score)
    }
    
    private func addGameEvent(event: GameEvent, timeStep: Int, otherData: AnyObject? = nil) {
        myEvents.append(PlayerEvent(event: event, timeStep: timeStep, otherData: otherData))
    }
}