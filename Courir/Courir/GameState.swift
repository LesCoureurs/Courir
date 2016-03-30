//
//  GameState.swift
//  Courir
//
//  Created by Ian Ngiaw on 3/20/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class GameState {
    var myPlayer: Player!
    var players = [Player]()
    private var numPlayers = 0
    var peerMapping = [MCPeerID: Int]()
    var scoreTracking = [Int: Int]()
    var obstacles = [Obstacle]()
    var currentSpeed = initialGameSpeed
    var distance = 0 // Score

    var isMultiplayer: Bool
    var gameIsOver = false
    
    init(isMultiplayer: Bool = false) {
        self.isMultiplayer = isMultiplayer
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
        for peer in allPeerIDs {
            peerMapping[peer] = numPlayers
            let player = Player(playerNumber: numPlayers, isMultiplayer: isMultiplayer)
            if peer == myPeerID {
                myPlayer = player
                player.ready()
            }
            players.append(player)
            numPlayers += 1
        }
    }

    func getPlayer(withPeerID peerID: MCPeerID) -> Player? {
        if let index = peerMapping[peerID] {
            return players[index]
        }
        return nil
    }
    
    func everyoneFinished() -> Bool {
        for player in players {
            if player.state != PlayerState.Lost {
                return false
            }
        }
        return true
    }
    
    func ownPlayerStillPlaying() -> Bool {
        return myPlayer.state != PlayerState.Lost
    }
    
    func updatePlayerScore(playerNumber: Int, score: Int) {
        scoreTracking[playerNumber] = score
    }
}