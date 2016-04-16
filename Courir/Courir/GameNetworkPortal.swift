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
    func gameStartSignalReceived(data: AnyObject?, peer: MCPeerID)
    func connectedToRoom(peer: MCPeerID)
    func disconnectedFromRoom(peer: MCPeerID)
}

protocol GameNetworkPortalGameStateDelegate: class {
    func gameReadySignalReceived(data: AnyObject?, peer: MCPeerID)
    func playerLostSignalReceived(data: AnyObject?, peer: MCPeerID)
    func jumpActionReceived(data: AnyObject?, peer: MCPeerID)
    func duckActionReceived(data: AnyObject?, peer: MCPeerID)
    func collideActionReceived(data: AnyObject?, peer: MCPeerID)
    func floatingObstacleReceived(data: AnyObject?, peer: MCPeerID)
    func nonfloatingObstacleReceived(data: AnyObject?, peer: MCPeerID)
    func disconnectedFromGame(peer: MCPeerID)
}

class GameNetworkPortal {
    static let _instance = GameNetworkPortal(playerName: me.name ?? myDeviceName)
    var semaphore: dispatch_semaphore_t!
    let semaphoreTimeout: Int64 = 200
    let serviceType = "courir"
    var isConnecting = false
    weak var connectionDelegate: GameNetworkPortalConnectionDelegate?
    weak var gameStateDelegate: GameNetworkPortalGameStateDelegate? {
        didSet {
            while !messageBacklog.isEmpty {
                let message = messageBacklog.removeAtIndex(0)
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), { self.handleDataPacket(message.data, peerID: message.peer) })
            }
        }
    }
    let coulombNetwork: CoulombNetwork!

    private var messageBacklog = [(data: NSData, peer: MCPeerID)]()

    private init(playerName deviceId: String) {
        // NOTE: coulombNetwork.autoAcceptGuests is defaulted to true
        // If autoAcceptGuests is set to false, implement 
        // CoulombNetworkDelegate.invitationToConnectReceived to handle invitation properly
        coulombNetwork = CoulombNetwork(serviceType: serviceType, myPeerId: myPeerID)
        coulombNetwork.delegate = self
        coulombNetwork.debugMode = true
        semaphore = dispatch_semaphore_create(0)
    }

    deinit {
        coulombNetwork.stopAdvertisingHost()
        coulombNetwork.stopSearchingForHosts()
    }

    // Some of the following methods are safe: they only execute when applicable, else just return
    // MARK: Hosting
    func beginHosting() {
        coulombNetwork.startAdvertisingHost()
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
    
    func getFoundHosts() -> [MCPeerID] {
        return coulombNetwork.getFoundHosts()
    }
    
    // MARK: Common methods
    func disconnectFromRoom() {
        let group = dispatch_group_create()
        
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            self.stopHosting()
            self.beginSearchingForHosts()
        })
        
        dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            self.coulombNetwork.disconnect()
        })
    }
    
    // MARK: Data transfer
    func send(event: GameEvent, data: AnyObject = "No data", mode: MCSessionSendDataMode = .Reliable) {
        let standardData = ["event": event.rawValue, "data": data]
        let encodedData = NSKeyedArchiver.archivedDataWithRootObject(standardData)
        sendData(encodedData, mode: mode)
    }

    // Send data to everyone in the session
    private func sendData(data: NSData, mode: MCSessionSendDataMode) {
        coulombNetwork.sendData(data, mode: mode)
    }
    
    func getMyPeerID() -> MCPeerID {
        return coulombNetwork.getMyPeerID()
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
        print("Portal: Connected Peers in sesison changed: \(peers)")
//        let timeout = dispatch_time(DISPATCH_TIME_NOW, semaphoreTimeout)
        
        // Only wait when connecting
        if isConnecting {
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            isConnecting = false
        }
        print("Portal: semaphore finished waiting")
        connectionDelegate?.playersInRoomChanged(peers)
    }
    
    func connectedToPeer(peer: MCPeerID) {
        connectionDelegate?.connectedToRoom(peer)
    }
    
    func connectingToPeer(peer: MCPeerID) {
        isConnecting = true
    }
    
    func disconnectedFromSession(peer: MCPeerID) {
        // Called when self is disconnected from a session
        // Stop hosting (if applicable) and begin searching for host again
        // Call delegate to take further actions e.g. segue
        isConnecting = false
        
        if gameStateDelegate != nil {
            gameStateDelegate?.disconnectedFromGame(peer)
        } else {
            connectionDelegate?.disconnectedFromRoom(peer)
        }
        
    }
    
    // Receives NSData and converts it into a dictionary of type [String: AnyObject]
    // All data packets must contain an event number which is keyed with the string
    // "event"
    func handleDataPacket(data: NSData, peerID: MCPeerID) {

        if let parsedData = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [String: AnyObject], eventNumber = parsedData["event"] as? Int, event = GameEvent(rawValue: eventNumber) {
            if gameStateDelegate == nil && event != .GameDidStart {
                messageBacklog.append((data: data, peer: peerID))
                return
            }
            switch event {
            case GameEvent.GameDidStart:
                connectionDelegate?.gameStartSignalReceived(parsedData["data"], peer: peerID)
            case GameEvent.GameReady:
                gameStateDelegate?.gameReadySignalReceived(parsedData["data"], peer: peerID)
            case GameEvent.PlayerLost:
                gameStateDelegate?.playerLostSignalReceived(parsedData["data"], peer: peerID)
            case GameEvent.PlayerDidJump:
                gameStateDelegate?.jumpActionReceived(parsedData["data"], peer: peerID)
            case GameEvent.PlayerDidDuck:
                gameStateDelegate?.duckActionReceived(parsedData["data"], peer: peerID)
            case GameEvent.PlayerDidCollide:
                gameStateDelegate?.collideActionReceived(parsedData["data"], peer: peerID)
            case GameEvent.FloatingObstacleGenerated:
                gameStateDelegate?.floatingObstacleReceived(parsedData["data"], peer: peerID)
            case GameEvent.NonFloatingObstacleGenerated:
                gameStateDelegate?.nonfloatingObstacleReceived(parsedData["data"], peer: peerID)
            default:
                break
            }
        }
    }
}
