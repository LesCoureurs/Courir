//
//  RoomViewController.swift
//  Courir
//
//  Created by Ian Ngiaw on 3/25/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit
import SpriteKit
import MultipeerConnectivity

private let cellIdentifier = "host-cell-identifer"

class RoomViewController: UIViewController {

    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var peersTableView: UITableView!
    
    private(set) var isHost = true
    private var peers = [MCPeerID]()
    private let portal = GameNetworkPortal._instance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        peersTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        portal.connectionDelegate = self
        
        peersTableView.dataSource = self
        
        if isHost {
            portal.beginHosting()
        } else {
            startButton.enabled = false
        }
    }

    @IBAction func startGame(sender: AnyObject) {
        portal.stopHosting()
        portal.stopSearchingForHosts()
        GameNetworkPortal._instance.send(.GameDidStart)
        presentGameScene()
    }

    private func presentGameScene() {
        performSegueWithIdentifier("startGameSegue", sender: self)
    }
    
    func playerIsNotHost() {
        isHost = false
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "startGameSegue" {
            let destination = segue.destinationViewController as! GameViewController
            destination.isMultiplayer = true
            destination.peers = peers
        }
    }
}

extension RoomViewController: UITableViewDataSource {
    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = peersTableView
            .dequeueReusableCellWithIdentifier(cellIdentifier)!
        let peerLabel = UILabel(frame: cell.frame)
        peerLabel.text = peers[indexPath.row].displayName
        cell.addSubview(peerLabel)
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peers.count
    }
}

extension RoomViewController: GameNetworkPortalConnectionDelegate {
    func foundHostsChanged(foundHosts: [MCPeerID]) {
        
    }
    
    func playerWantsToJoinRoom(peer: MCPeerID, acceptGuest: (Bool) -> Void) {
        acceptGuest(true)
    }
    
    func playersInRoomChanged(peerIDs: [MCPeerID], host: MCPeerID) {
        peers = peerIDs
        dispatch_async(dispatch_get_main_queue(), { self.peersTableView.reloadData() })
    }
    
    func disconnectedFromRoom() {

    }
}

// MARK: GameNetworkPortalGameStateDelegate
extension RoomViewController: GameNetworkPortalGameStateDelegate {
    func jumpActionReceived(data: [String : AnyObject], peer: MCPeerID) {
        fatalError("Method jumpActionReceived not implemented")
    }

    func duckActionReceived(data: [String : AnyObject], peer: MCPeerID) {
        fatalError("Method duckActionReceived not implemented")
    }

    func collideActionReceived(data: [String : AnyObject], peer: MCPeerID) {
        fatalError("Method collideActionReceived not implemented")
    }

    func gameStartSignalReceived(data: [String : AnyObject], peer: MCPeerID) {
        if let data = data as? [String: String] where data["action"] == "start" {
            presentGameScene()
        }
    }

    func gameEndSignalReceived(data: [String : AnyObject], peer: MCPeerID) {

    }
}