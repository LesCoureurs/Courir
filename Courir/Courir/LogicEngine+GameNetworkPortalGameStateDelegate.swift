//
//  LogicEngine+GameNetworkPortalGameStateDelegate.swift
//  Courir
//
//  Created by Karen on 5/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Foundation
import MultipeerConnectivity

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

    func floatingObstacleReceived(data: AnyObject?, peer: MCPeerID) {
        handleObstacleGeneration(.FloatingObstacleGenerated, data: data, peer: peer)
    }

    func nonfloatingObstacleReceived(data: AnyObject?, peer: MCPeerID) {
        handleObstacleGeneration(.NonFloatingObstacleGenerated, data: data, peer: peer)
    }

    private func handleObstacleGeneration(event: GameEvent, data: AnyObject?, peer: MCPeerID) {
        guard let playerNumber = state.host?.playerNumber,
            dataDict = data as? [String: AnyObject],
            occurringTimeStep = dataDict["time_step"] as? Int else {
                return
        }
        appendToEventQueue(event, playerNumber: playerNumber, occurringTimeStep: occurringTimeStep)
    }

    func gameReadySignalReceived(data: AnyObject?, peer: MCPeerID) {
        state.playerReady(peer)
    }

    func playerLostSignalReceived(data: AnyObject?, peer: MCPeerID) {
        guard let dataDict = data as? [String: AnyObject],
            playerNumber = state.peerMapping[peer],
            score = dataDict["score"] as? Int,
            occurringTimeStep = dataDict["time_step"] as? Int else {
                return
        }
        
        appendToEventQueue(.PlayerLost, playerNumber: playerNumber,
                           occurringTimeStep: occurringTimeStep, otherData: score)
    }


    func disconnectedFromGame() {
        
    }
}
