//
//  GameNetworkPortal.swift
//  Courir
//
//  Created by Hieu Giang on 20/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Coulomb
import MultipeerConnectivity

internal protocol GameNetworkPortalConnectionDelegate {
    func foundHostsChanged(foundHosts: [MCPeerID])
    func playerWantsToJoinRoom(peer: MCPeerID, acceptGuest: (Bool) -> Void)
    func playersInRoomChanged(peerIDs: [MCPeerID])
    func disconnectedFromRoom()
    
}

internal protocol GameNetworkPortalGameStateDelegate {
    func jumpActionReceived()
    func duckActionReceived()
    func collideActionReceived()
    func gameStartSignalReceived()
    func gameEndSignalReceived()
}

class GameNetworkPortal {
    let serviceType = "courir"
    var connectionDelegate: GameNetworkPortalConnectionDelegate?
    var gameStateDelegate: GameNetworkPortalGameStateDelegate?
    var coulombNetwork: CoulombNetwork!

    init(playerName deviceId: String) {
        // coulombNetwork.autoAcceptGuests is defaulted to true
        coulombNetwork = CoulombNetwork(serviceType: serviceType, deviceId: deviceId)
        coulombNetwork.delegate = self
    }
    
    // MARK: Hosting
    func beginHosting() {
        coulombNetwork.startAdversitingHost()
    }
    
    func stopHosting() {
        coulombNetwork.stopAdvertisingHost()
    }
    
    // MARK: Looking for hosts
    func beginSearchingForHosts() {
        coulombNetwork.startSearchingForHosts()
    }
    
    func stopSearchingForHosts() {
        coulombNetwork.stopSearchingForHosts()
    }
    
    func connectToHost(host: MCPeerID) {
        coulombNetwork.connectToHost(host)
    }
    
    // MARK: Common methods
    func disconnectFromRoom() {
        coulombNetwork.disconnect()
    }
    
    // MARK: Data transfer
    
    // Send data to everyone in the session
    func sendData(data: NSData, mode: MCSessionSendDataMode) {
        coulombNetwork.sendData(data, mode: mode)
    }
    
    // Convert struct to NSData using pointer
    func prepareData(gameChange: GameChange) -> NSData {
        var mutableGameChange = gameChange
        return withUnsafePointer(&mutableGameChange) { p in
            NSData(bytes: p, length: sizeofValue(mutableGameChange))
        }
    }
}

extension GameNetworkPortal: CoulombNetworkDelegate {
    func foundHostsChanged(foundHosts: [MCPeerID]) {
        connectionDelegate?.foundHostsChanged(foundHosts)
    }
    
    func invitationToConnectReceived(peer: MCPeerID, handleInvitation: (Bool) -> Void) {
        // If autoAcceptGuests is true, this method won't be called.
        // Else, call connectionDelegate method to handle
        connectionDelegate?.playerWantsToJoinRoom(peer, acceptGuest: handleInvitation)
    }
    
    func connectedPeersInSessionChanged(peers: [MCPeerID]) {
        connectionDelegate?.playersInRoomChanged(peers)
    }
    
    func connectedToPeer(peer: MCPeerID) {}
    
    func disconnectedFromSession() {
        // Disconnected from a session
        // Begin searching for host again
        // Call delegate to take further actions e.g. segue
        beginSearchingForHosts()
        connectionDelegate?.disconnectedFromRoom()
    }
    
    // Receive data packet, unpack and call appropriate handler
    func handleDataPacket(data: NSData, peerID: MCPeerID) {
        let content = unpackData(data)
        switch content.event {
        case GameEvent.GameDidStart:
            gameStateDelegate?.gameStartSignalReceived()
        case GameEvent.GameDidEnd:
            gameStateDelegate?.gameEndSignalReceived()
        case GameEvent.PlayerDidJump:
            gameStateDelegate?.jumpActionReceived()
        case GameEvent.PlayerDidDuck:
            gameStateDelegate?.duckActionReceived()
        case GameEvent.PlayerDidCollide:
            gameStateDelegate?.collideActionReceived()
        default:
            return
        }
    }
    
    // Convert NSData to GameChange struct
    func unpackData(data: NSData) -> GameChange {
        let pointer = UnsafeMutablePointer<GameChange>.alloc(sizeof(GameChange))
        data.getBytes(pointer, length: sizeof(GameChange))
        
        return pointer.move()
    }
}
