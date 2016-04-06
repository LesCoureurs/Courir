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
    public var debugMode = false
    public var autoAcceptGuests = true
    
    static let defaultTimeout: NSTimeInterval = 30
    private var serviceAdvertiser: MCNearbyServiceAdvertiser?
    private var serviceBrowser: MCNearbyServiceBrowser?
    private var foundHosts = [MCPeerID]()
    
    public weak var delegate: CoulombNetworkDelegate?
    
    private lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil,
                                encryptionPreference: .Required)
        session.delegate = self
        return session
    }()
    
    private let myPeerId: MCPeerID
    private var host: MCPeerID?
    private let serviceType: String
    
    public init(serviceType: String, deviceId: String) {
        self.serviceType = serviceType
        myPeerId = MCPeerID(displayName: deviceId)
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
        self.host = myPeerId
        if serviceAdvertiser == nil {
            serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId,
                                                          discoveryInfo: ["peerType": "host"], serviceType: serviceType)
            serviceAdvertiser?.delegate = self
        }
        serviceAdvertiser?.startAdvertisingPeer()
    }
    
    public func stopAdvertisingHost() {
        serviceAdvertiser?.stopAdvertisingPeer()
    }
    
    // MARK: Methods for guest
    public func startSearchingForHosts() {
        self.host = nil
        if serviceBrowser == nil {
            serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
            serviceBrowser?.delegate = self
        }
        foundHosts = []
        serviceBrowser?.startBrowsingForPeers()
    }
    
    public func stopSearchingForHosts() {
        serviceBrowser?.stopBrowsingForPeers()
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
        if self.host == nil {
            self.host = host
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
        DLog("%@", "disconnected from \(session.hashValue)")
    }
    
    // This method is async
    public func sendData(data: NSData, mode: MCSessionSendDataMode) -> Bool {
        do {
            try session.sendData(data, toPeers: session.connectedPeers, withMode: mode)
        } catch {
            return false
        }
        
        return true
    }
    
    public func getMyPeerID() -> MCPeerID {
        return myPeerId
    }
    // Debug mode
    private func DLog(message: String, _ function: String) {
        if debugMode {
            NSLog(message, function)
        }
    }
}

extension CoulombNetwork: MCNearbyServiceAdvertiserDelegate {
    // Invitation is received from guest
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
    // Peer is found in browser
    public func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID,
                        withDiscoveryInfo info: [String : String]?) {
        DLog("%@", "foundPeer: \(peerID)")
        
        guard let discoveryInfo = info else {
            return
        }
        guard discoveryInfo["peerType"] == "host" else {
            return
        }
        
        DLog("%@", "invitePeer: \(peerID)")
        foundHosts.append(peerID)
        delegate?.foundHostsChanged(foundHosts)
    }
    
    // Peer is lost in browser
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
                
                // Pass to delegate
                delegate?.connectedToPeer(peerID)
            } else {
                DLog("%@", "not connected to \(session.hashValue)")
                // If self is disconnected or current host is disconnected
                if self.host == peerID {
                    DLog("%@", "Host was removed")
                    session.disconnect()
                    delegate?.disconnectedFromSession()
                }
            }
            
            delegate?.connectedPeersInSessionChanged(session.connectedPeers)
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

extension MCSessionState {
    func stringValue() -> String {
        switch(self) {
        case .NotConnected: return "NotConnected"
        case .Connecting: return "Connecting"
        case .Connected: return "Connected"
        }
    }
}