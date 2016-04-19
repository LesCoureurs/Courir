//
//  CoulombNetwork.swift
//  Coulomb
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
    func connectingToPeer(peer: MCPeerID)
    func disconnectedFromSession(peer: MCPeerID)
    func handleDataPacket(data: NSData, peerID: MCPeerID)
}

public class CoulombNetwork: NSObject {
    // MARK: Public settings
    /// Toggle on/off to print DLog messages to console
    public var debugMode = false
    public var autoAcceptGuests = true
    public var maxNumPeerInRoom = 4
    
    // MARK: Private settings
    static let defaultTimeout: NSTimeInterval = 7
    private var serviceAdvertiser: MCNearbyServiceAdvertiser?
    private var serviceBrowser: MCNearbyServiceBrowser?
    private var foundHosts = [MCPeerID]()
    private let myPeerId: MCPeerID
    private var host: MCPeerID?
    private let serviceType: String
    
    public weak var delegate: CoulombNetworkDelegate?
    
    private lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil,
                                encryptionPreference: .Required)
        session.delegate = self
        return session
    }()
    
    public init(serviceType: String, myPeerId: MCPeerID) {
        self.serviceType = serviceType
        self.myPeerId = myPeerId
    }
    
    deinit {
        stopAdvertisingHost()
        stopSearchingForHosts()
        session.disconnect()
    }
    
    // MARK: Methods for host
    /// Start advertising.
    /// Assign advertiser delegate
    public func startAdvertisingHost() {
        stopSearchingForHosts()
        self.host = myPeerId

        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId,
                                                      discoveryInfo: ["peerType": "host"], serviceType: serviceType)
        self.serviceAdvertiser?.delegate = self
        
        self.serviceAdvertiser?.startAdvertisingPeer()
    }
    
    /// Stop advertising.
    /// Unassign advertiser delegate
    public func stopAdvertisingHost() {
        serviceAdvertiser?.stopAdvertisingPeer()
        serviceAdvertiser?.delegate = nil
    }
    
    // MARK: Methods for guest
    /// Start looking for discoverable hosts
    public func startSearchingForHosts() {
        self.host = nil

        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        serviceBrowser?.delegate = self

        foundHosts = []
        serviceBrowser?.startBrowsingForPeers()
    }
    
    /// Stop looking for hosts
    public func stopSearchingForHosts() {
        serviceBrowser?.stopBrowsingForPeers()
    }
    
    /// Send inivitation to connect to a host
    public func connectToHost(host: MCPeerID, context: NSData? = nil, timeout: NSTimeInterval = defaultTimeout) {
        guard foundHosts.contains(host) else {
            return
        }
        
        DLog("%@", "connect to host: \(host)")
        serviceBrowser?.invitePeer(host, toSession: session, withContext: context, timeout: timeout)
        
        // If the session is still without host, assign a new one
        if self.host == nil {
            self.host = host
        }
    }
    
    /// Get the list of discovered hosts
    public func getFoundHosts() -> [MCPeerID] {
        return foundHosts
    }
    
    // MARK: Methods for session
    /// Called when deliberately disconnect.
    /// Disconnect from current session, browse for another host
    public func disconnect() {
        session.disconnect()
        host = nil
        DLog("%@", "disconnected from \(session.hashValue)")
    }
    
    /// Send data to every peer in session
    public func sendData(data: NSData, mode: MCSessionSendDataMode) -> Bool {
        do {
            try session.sendData(data, toPeers: session.connectedPeers, withMode: mode)
        } catch {
            return false
        }
        
        return true
    }
    
    /// Return my peer ID
    public func getMyPeerID() -> MCPeerID {
        return myPeerId
    }
    
    /// Debug mode
    private func DLog(message: String, _ function: String) {
        if debugMode {
            NSLog(message, function)
        }
    }
}

extension CoulombNetwork: MCNearbyServiceAdvertiserDelegate {
    /// Invitation is received from guest
    public func advertiser(advertiser: MCNearbyServiceAdvertiser,
                           didReceiveInvitationFromPeer peerID: MCPeerID,
                                                        withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        DLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        
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
    /// Peer is found in browser
    public func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID,
                        withDiscoveryInfo info: [String : String]?) {
        DLog("%@", "foundPeer: \(peerID)")
        
        guard let discoveryInfo = info else {
            return
        }
        guard discoveryInfo["peerType"] == "host" else {
            return
        }
        
        foundHosts.append(peerID)
        delegate?.foundHostsChanged(foundHosts)
    }
    
    /// Peer is lost in browser
    public func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard foundHosts.contains(peerID) else {
            return
        }
        DLog("%@", "lostPeer: \(peerID)")
        let index = foundHosts.indexOf(peerID)!
        foundHosts.removeAtIndex(index)
        delegate?.foundHostsChanged(foundHosts)
    }
}

extension CoulombNetwork: MCSessionDelegate {
    // Handles MCSessionState changes: NotConnected, Connecting and Connected.
    public func session(session: MCSession, peer peerID: MCPeerID,
                        didChangeState state: MCSessionState) {
        DLog("%@", "peer \(peerID) didChangeState: \(state.stringValue())")
        if state != .Connecting {
            if state == .Connected {
                DLog("%@", "connected to \(session.hashValue)")
                // If currently a guest, stop looking for host
                stopSearchingForHosts()
                
                if self.host == peerID {
                    if session.connectedPeers.count >= maxNumPeerInRoom {
                        disconnect()
                        return
                    } else {
                        // Pass to delegate
                        delegate?.connectedToPeer(peerID)
                    }
                }
            } else {
                DLog("%@", "not connected to \(session.hashValue)")
                
                // If self is disconnected from current host
                if self.host == peerID {
                    DLog("%@", "disconnected from host")
                    session.disconnect()
                    delegate?.disconnectedFromSession(peerID)
                    return
                }
            }
            // If self did not disconnect deliberately
            if self.host != nil {
                delegate?.connectedPeersInSessionChanged(session.connectedPeers)
            }
        } else {
            delegate?.connectingToPeer(peerID)
        }
    }
    
    // Handles incomming NSData
    public func session(session: MCSession, didReceiveData data: NSData,
                        fromPeer peerID: MCPeerID) {
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

// MARK: For Dlog messages
extension MCSessionState {
    func stringValue() -> String {
        switch(self) {
        case .NotConnected: return "NotConnected"
        case .Connecting: return "Connecting"
        case .Connected: return "Connected"
        }
    }
}