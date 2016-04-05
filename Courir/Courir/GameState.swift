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
    var myPlayer: Player!
    var players = [Player]()
    var peerMapping = [MCPeerID: Int]()
    var scoreTracking = [MCPeerID: Int]()

    var obstacles = [Obstacle]() {
        didSet {
            observer?.didChangeProperty("obstacles", from: self)
        }
    }
    
    var currentSpeed = initialGameSpeed
    var distance = 0 // Score

    private (set) var mode: GameMode
    var isMultiplayer: Bool {
        return mode == .Multiplayer || mode == .SpecialMultiplayer
    }
    var gameIsOver = false {
        didSet {
            observer?.didChangeProperty("gameIsOver", from: self)
        }
    }
    
    weak var observer: Observer?
    
    init(mode: GameMode = .SinglePlayer) {
        self.mode = mode
    }

    var objects: [GameObject] {
        return players.map {$0 as GameObject} + obstacles.map {$0 as GameObject}
    }

    var allPlayersReady: Bool {
        return players.filter { $0.state == PlayerState.Ready }.count == players.count
    }

    func initPlayers(peers: [MCPeerID]) {
        let peers = peers
        var allPeerIDs = peers

        allPeerIDs.append(myPeerID)
        allPeerIDs.sortInPlace({ (this, other) in this.displayName < other.displayName })

        for (playerNum, peer) in allPeerIDs.enumerate() {
            let player = Player(playerNumber: playerNum, isMultiplayer: isMultiplayer, numPlayers: allPeerIDs.count)
            if peer == myPeerID {
                myPlayer = player
                player.ready()
            }
            peerMapping[peer] = playerNum
            players.append(player)
        }
    }

    func getPlayer(withPeerID peerID: MCPeerID) -> Player? {
        if let index = peerMapping[peerID] {
            return players[index]
        }
        return nil
    }
    
    func everyoneFinished() -> Bool {
        return scoreTracking.count == players.count
    }
    
    func ownPlayerStillPlaying() -> Bool {
        return myPlayer.state != PlayerState.Lost
    }
    
    func updatePlayerScore(peerID: MCPeerID, score: Int) {
        scoreTracking[peerID] = score
    }
}