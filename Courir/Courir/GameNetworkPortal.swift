//
//  GameNetworkPortal.swift
//  Courir
//
//  Created by Hieu Giang on 20/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Coulomb
import MultipeerConnectivity

internal protocol GameNetworkPortalProtocol {
    
}

class GameNetworkPortal {
    let serviceType = "courir"
    var coulombNetwork: CoulombNetwork!
    
    init(deviceId: String) {
        coulombNetwork = CoulombNetwork(serviceType: serviceType, deviceId: deviceId)
    }
    
    init() {
        coulombNetwork = CoulombNetwork(serviceType: serviceType)
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
    
    func connectionsChanged(peers: [MCPeerID]) {}
    
    func connectedToPeer(peer: MCPeerID) {}
    
    func handleDataPacket(data: NSData, peerID: MCPeerID) {}
}
