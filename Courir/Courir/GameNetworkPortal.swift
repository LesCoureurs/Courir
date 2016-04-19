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
    static let _instance = GameNetworkPortal(playerName: me.name ?? me.deviceName)
    var semaphore: dispatch_semaphore_t?
    let semaphoreTimeout: Int64 = 200
    let serviceType = "courir"
    var isMovingToRoomView = false
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
        coulombNetwork = CoulombNetwork(serviceType: serviceType, myPeerId: me.peerID)
        coulombNetwork.delegate = self
        coulombNetwork.debugMode = true
        createSemaphore()
    }

    deinit {
        coulombNetwork.stopAdvertisingHost()
        coulombNetwork.stopSearchingForHosts()
    }

    // MARK: Hosting
    /// Call library function to start hosting
    func beginHosting() {
        coulombNetwork.startAdvertisingHost()
    }
    
    /// Call library function to stop hosting
    func stopHosting() {
        coulombNetwork.stopAdvertisingHost()
    }
    
    // MARK: Looking for hosts
    /// Call library function to start looking for host
    func beginSearchingForHosts() {
        coulombNetwork.startSearchingForHosts()
    }
    
    /// Call library function to stop looking for host
    func stopSearchingForHosts() {
        coulombNetwork.stopSearchingForHosts()
    }
    
    /// Attempt to connect to host
    func connectToHost(host: MCPeerID) {
        coulombNetwork.connectToHost(host)
    }
    
    /// Get the currently discoverable hosts
    func getFoundHosts() -> [MCPeerID] {
        return coulombNetwork.getFoundHosts()
    }
    
    // MARK: Common methods
    /// Called when own device wants to deliberately exit a room
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
    
    /// Return peer id of own device
    func getMyPeerID() -> MCPeerID {
        return coulombNetwork.getMyPeerID()
    }
    
    // MARK: Data transfer
    /// Send data to everyone in the session
    func send(event: GameEvent, data: AnyObject = "No data", mode: MCSessionSendDataMode = .Reliable) {
        let standardData = ["event": event.rawValue, "data": data]
        let encodedData = NSKeyedArchiver.archivedDataWithRootObject(standardData)
        coulombNetwork.sendData(encodedData, mode: mode)
    }
    
    // MARK: Semaphore
    func createSemaphore() {
        semaphore = dispatch_semaphore_create(0)
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
    
    /// Wait for semaphore to make sure the correct delegate is assigned
    func connectedPeersInSessionChanged(peers: [MCPeerID]) {
        // Only wait when connecting
        if isMovingToRoomView && semaphore != nil {
            dispatch_semaphore_wait(semaphore!, DISPATCH_TIME_FOREVER)
            isMovingToRoomView = false
        }
        connectionDelegate?.playersInRoomChanged(peers)
    }
    
    func connectedToPeer(peer: MCPeerID) {
        isMovingToRoomView = true
        connectionDelegate?.connectedToRoom(peer)
    }
    
    func connectingToPeer(peer: MCPeerID) {
        createSemaphore()
    }
    
    /// Called when self is disconnected from a session
    /// Stop hosting (if applicable) and begin searching for host again
    /// Call delegate to take further actions e.g. segue
    func disconnectedFromSession(peer: MCPeerID) {
        isMovingToRoomView = false
        
        if gameStateDelegate != nil {
            gameStateDelegate?.disconnectedFromGame(peer)
        } else {
            connectionDelegate?.disconnectedFromRoom(peer)
        }
        
    }
    
    /// Receives NSData and converts it into a dictionary of type [String: AnyObject]
    /// All data packets must contain an event number which is keyed with the string
    /// "event"
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
