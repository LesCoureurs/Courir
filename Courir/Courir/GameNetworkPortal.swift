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
    func playerJoinedRoom()
    func playersInRoomChanged()
    func disconnectedFromRoom()
    
}

internal protocol GameNetworkPortalGameStateDelegate {
    func jumpActionReceived() {}
    func duckActionReceived() {}
    func collideActionReceived() {}
    func gameStartSignalReceived() {}
    func gameEndSignalReceived() {}
}

class GameNetworkPortal {
    let serviceType = "courir"
    var connectionDelegate: GameNetworkPortalConnectionDelegate?
    var gameStateDelegate: GameNetworkPortalGameStateDelegate
    var coulombNetwork: CoulombNetwork!

    init(playerName deviceId: String) {
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
    
    func prepareData() -> NSData {
        return
    }
}

extension GameNetworkPortal: CoulombNetworkDelegate {
    func foundHostsChanged(foundHosts: [MCPeerID]) {
        
    }
    
    func invitationToConnectReceived(peer: MCPeerID, handleInvitation: (Bool) -> Void) {}
    
    func connectedPeersInSessionChanged(peers: [MCPeerID]) {}
    
    func connectedToPeer(peer: MCPeerID) {}
    
    func disconnectedFromSession() {
        // Disconnected from a session
        // Begin searching for host again
        // Call delegate to take further actions e.g. segue
        beginSearchingForHosts()
        connectionDelegate?.disconnectedFromRoom()
    }
    
    func handleDataPacket(data: NSData, peerID: MCPeerID) {}
}
