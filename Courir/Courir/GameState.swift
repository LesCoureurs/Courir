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
    var myPlayer: Player
    var players = [Player]()
    private var numPlayers = 0
    var peerMapping = [MCPeerID: Int]()
    var obstacles = [Obstacle]()
    var currentSpeed = initialGameSpeed
    var distance = 0 // Score

    var isMultiplayer: Bool
    var gameIsOver = false
    
    init(player: Player, isMultiplayer: Bool = false) {
        self.isMultiplayer = isMultiplayer
        myPlayer = player
        players.append(myPlayer)
        numPlayers += 1
        peerMapping[myPeerID] = myMultiplayerModeNumber
    }

    var objects: [GameObject] {
        return players.map {$0 as GameObject} + obstacles.map {$0 as GameObject}
    }

    var allPlayersReady: Bool {
        return players.filter { $0.state == PlayerState.Ready }.count == players.count
    }

    func initPeers(peers: [MCPeerID]) {
        for peer in peers {
            peerMapping[peer] = numPlayers
            let player = Player(playerNumber: numPlayers, isMultiplayer: isMultiplayer)
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
}