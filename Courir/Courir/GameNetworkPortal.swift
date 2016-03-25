//
//  GameNetworkPortal.swift
//  Courir
//
//  Created by Hieu Giang on 20/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Coulomb
import MultipeerConnectivity

protocol GameNetworkPortalConnectionDelegate: class {
    func foundHostsChanged(foundHosts: [MCPeerID])
    func playerWantsToJoinRoom(peer: MCPeerID, acceptGuest: (Bool) -> Void)
    func playersInRoomChanged(peerIDs: [MCPeerID])
    func disconnectedFromRoom()
}

protocol GameNetworkPortalGameStateDelegate: class {
    func jumpActionReceived(data: [String: NSObject], peer: MCPeerID)
    func duckActionReceived(data: [String: NSObject], peer: MCPeerID)
    func collideActionReceived(data: [String: NSObject], peer: MCPeerID)
    func gameStartSignalReceived(data: [String: NSObject], peer: MCPeerID)
    func gameEndSignalReceived(data: [String: NSObject], peer: MCPeerID)
}

class GameNetworkPortal {
    static let _instance = GameNetworkPortal(playerName: myDeviceName)

    let serviceType = "courir"
    weak var connectionDelegate: GameNetworkPortalConnectionDelegate?
    weak var gameStateDelegate: GameNetworkPortalGameStateDelegate?
    var coulombNetwork: CoulombNetwork!

    private init(playerName deviceId: String) {
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
    // TODO: Test this
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
            gameStateDelegate?.gameStartSignalReceived(content.data, peer: peerID)
        case GameEvent.GameDidEnd:
            gameStateDelegate?.gameEndSignalReceived(content.data, peer: peerID)
        case GameEvent.PlayerDidJump:
            gameStateDelegate?.jumpActionReceived(content.data, peer: peerID)
        case GameEvent.PlayerDidDuck:
            gameStateDelegate?.duckActionReceived(content.data, peer: peerID)
        case GameEvent.PlayerDidCollide:
            gameStateDelegate?.collideActionReceived(content.data, peer: peerID)
        default:
            return
        }
    }
    
    // Convert NSData to GameChange struct
    // TODO: Test this
    func unpackData(data: NSData) -> GameChange {
        let pointer = UnsafeMutablePointer<GameChange>.alloc(sizeof(GameChange))
        data.getBytes(pointer, length: sizeof(GameChange))
        
        return pointer.move()
    }
}
