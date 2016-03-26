//
//  Sploosh.swift
//  NetworkLib
//
//  Created by Ian Ngiaw on 3/14/16.
//  Copyright © 2016 nus.cs3217.group5. All rights reserved.
//

import MultipeerConnectivity
import UIKit

public protocol CoulombNetworkDelegate: class {
    func foundHostsChanged(foundHosts: [MCPeerID])
    func invitationToConnectReceived(peer: MCPeerID, handleInvitation: (Bool) -> Void)
    func connectedPeersInSessionChanged(peers: [MCPeerID])
    func connectedToPeer(peer: MCPeerID)
    func disconnectedFromSession()
    func handleDataPacket(data: NSData, peerID: MCPeerID)
}

public class CoulombNetwork: NSObject {
    public var autoAcceptGuests = true
    
    static let defaultTimeout: NSTimeInterval = 30
    private var serviceAdvertiser: MCNearbyServiceAdvertiser?
    private var serviceBrowser: MCNearbyServiceBrowser?
    private var foundHosts = [MCPeerID]()
    
    // A set of all peers in the session.
    // We need this since session.connectedPeers only contains peers except self.
    // Useful for discovering disconnection.
    private var peersInSession: Set<MCPeerID>
    
    public weak var delegate: CoulombNetworkDelegate?
    
    private lazy var session: MCSessionWithHost = {
        let session = MCSessionWithHost(peer: self.myPeerId, securityIdentity: nil,
            encryptionPreference: .Required)
        session.delegate = self
        return session
    }()
    
    private let myPeerId: MCPeerID
    private let serviceType: String
    
    public init(serviceType: String, deviceId: String) {
        self.serviceType = serviceType
        myPeerId = MCPeerID(displayName: deviceId)
        peersInSession = Set<MCPeerID>()
    }
    
    public convenience init(serviceType: String) {
        let myDeviceId = UIDevice.currentDevice().name
        self.init(serviceType: serviceType, deviceId: myDeviceId)
    }
    
    deinit {
        stopAdvertisingHost()
        stopSearchingForHosts()
    }
    
    // MARK: Methods for host
    public func startAdvertisingHost() {
        if serviceAdvertiser == nil {
            serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId,
                discoveryInfo: ["peerType": "host"], serviceType: serviceType)
            serviceAdvertiser?.delegate = self
        }
        serviceAdvertiser?.startAdvertisingPeer()
    }
    
    public func stopAdvertisingHost() {
        if let advertiser = serviceAdvertiser {
            advertiser.stopAdvertisingPeer()
        }
    }
    
    // MARK: Methods for guest
    public func startSearchingForHosts() {
        if serviceBrowser == nil {
            serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
            serviceBrowser?.delegate = self
        }
        foundHosts = []
        serviceBrowser?.startBrowsingForPeers()
    }
    
    public func stopSearchingForHosts() {
        if let browser = serviceBrowser {
            browser.stopBrowsingForPeers()
        }
    }
    
    public func connectToHost(host: MCPeerID, context: NSData? = nil, timeout: NSTimeInterval = defaultTimeout) {
        guard foundHosts.contains(host) else {
            return
        }
        
        guard let browser = serviceBrowser else {
            return
        }
        
        browser.invitePeer(host, toSession: session, withContext: context, timeout: timeout)
        
        // If the session is still without host, assign a new one
        if session.host == nil {
            session.host = host
        }
    }
    
    public func getFoundHosts() -> [MCPeerID] {
        return foundHosts
    }
    
    // MARK: Methods for session
    public func getConnectedPeers() -> [MCPeerID] {
        return session.connectedPeers
    }
    
    // When deliberately disconnect
    // Disconnect from current session, browse for another host
    public func disconnect() {
        session.disconnect()
        NSLog("%@", "disconnected from \(session.hashValue)")
        stopAdvertisingHost()
        startSearchingForHosts()
    }
    
    // This method is async
    public func sendData(data: NSData, mode: MCSessionSendDataMode) -> Bool {
        do {
            NSLog("%@", "send data to host: \(data)")
            try session.sendData(data, toPeers: session.connectedPeers, withMode: mode)
        } catch {
            NSLog("%@", "send data failed: \(data)")
            return false
        }
        
        return true
    }
}

extension CoulombNetwork: MCNearbyServiceAdvertiserDelegate {
    // Invitation is received from guest
    public func advertiser(advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
            NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
            
            let acceptGuest = {
                (accepted: Bool) -> Void in
                invitationHandler(accepted, self.session)
            }
            
            if autoAcceptGuests {
                acceptGuest(true)
            } else {
                delegate?.invitationToConnectReceived(peerID, handleInvitation: acceptGuest)
            }
    }
}

extension CoulombNetwork: MCNearbyServiceBrowserDelegate {
    // Peer is found in browser
    public func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String : String]?) {
            NSLog("%@", "foundPeer: \(peerID)")
            
            guard let discoveryInfo = info else {
                return
            }
            guard discoveryInfo["peerType"] == "host" else {
                return
            }
            
            NSLog("%@", "invitePeer: \(peerID)")
            foundHosts.append(peerID)
            delegate?.foundHostsChanged(foundHosts)
    }
    
    // Peer is lost in browser
    public func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard foundHosts.contains(peerID) else {
            return
        }
        
        let index = foundHosts.indexOf(peerID)!
        foundHosts.removeAtIndex(index)
        delegate?.foundHostsChanged(foundHosts)
    }
}

extension CoulombNetwork: MCSessionDelegate {
    // Handles MCSessionState changes: NotConnected, Connecting and Connected.
    public func session(session: MCSession, peer peerID: MCPeerID,
        didChangeState state: MCSessionState) {
            NSLog("%@", "peer \(peerID) didChangeState: \(state.stringValue())")
            if state != .Connecting {
                if state == .Connected {
                    NSLog("%@", "connected to \(session.hashValue)")
                    // Update the set of peers in the session
                    peersInSession.insert(peerID)
                    
                    // If currently a guest, stop looking for host
                    stopSearchingForHosts()
                    
                    // Pass to delegate
                    delegate?.connectedToPeer(peerID)
                } else {
                    NSLog("%@", "not connected to \(session.hashValue)")
                    
                    // If session.connectedPeers is empty, it implies that either:
                    // - Self is disconnected from the session
                    // - The session has no other connected peer
                    // Combine with peersInSession count > 1, we can be certain that
                    // self is disconnected.
                    if session.connectedPeers.isEmpty && peersInSession.count > 1 {
                        peersInSession.remove(myPeerId)
                        delegate?.disconnectedFromSession()
                    }
                }
                
                delegate?.connectedPeersInSessionChanged(session.connectedPeers)
            }
    }
    
    // Handles incomming NSData
    public func session(session: MCSession, didReceiveData data: NSData,
        fromPeer peerID: MCPeerID) {
            NSLog("%@", "Data received: \(data)")
            delegate?.handleDataPacket(data, peerID: peerID)
    }
    
    // Handles incoming NSInputStream
    public func session(session: MCSession, didReceiveStream stream: NSInputStream,
        withName streamName: String, fromPeer peerID: MCPeerID) {
            
    }
    
    // Handles finish receiving resource
    public func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
            
    }
    
    // Handles start receiving resource
    public func session(session: MCSession, didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
            
    }
}

extension MCSessionState {
    func stringValue() -> String {
        switch(self) {
        case .NotConnected: return "NotConnected"
        case .Connecting: return "Connecting"
        case .Connected: return "Connected"
        }
    }
}