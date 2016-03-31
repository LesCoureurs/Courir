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
    var peerMapping = [MCPeerID: Int]()

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
}