//
//  RoomSelectionViewController.swift
//  Courir
//
//  Created by Ian Ngiaw on 3/25/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit
import MultipeerConnectivity

private let cellIdentifier = "host-cell-identifer"

class RoomSelectionViewController: UIViewController {
    
    @IBOutlet weak var roomsAvailableTableView: UITableView!
    var hosts = [MCPeerID]()
    
    let portal = GameNetworkPortal._instance

    override func viewDidLoad() {
        super.viewDidLoad()
        roomsAvailableTableView.delegate = self
        roomsAvailableTableView.dataSource = self
        
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "enterRoomSegue" {
            let roomViewController = segue.destinationViewController as! RoomViewController
            roomViewController.playerIsNotHost()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        portal.connectionDelegate = self
        portal.stopHosting()
        portal.beginSearchingForHosts()
    }

    @IBAction func unwindToRoomSelectionFromRoomView(segue: UIStoryboardSegue) {
    }
    
    @IBAction func unwindToRoomSelectionFromGameView(segue: UIStoryboardSegue) {
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBAction func refreshButtonPressed(sender: AnyObject) {
        portal.stopSearchingForHosts()
        portal.beginSearchingForHosts()
        hosts = portal.getFoundHosts()
        dispatch_async(dispatch_get_main_queue(), {
            self.roomsAvailableTableView.reloadData()
        })
    }
}

// MARK: UITableViewDelegate
extension RoomSelectionViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        portal.connectToHost(hosts[indexPath.row])
    }
}

extension RoomSelectionViewController: UITableViewDataSource {
    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = roomsAvailableTableView
            .dequeueReusableCellWithIdentifier(cellIdentifier)!
        let hostLabel = UILabel(frame: cell.frame)
        hostLabel.text = hosts[indexPath.row].displayName
        cell.addSubview(hostLabel)
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hosts.count
    }
}

// MARK: GameNetworkPortalConnectionDelegate
extension RoomSelectionViewController: GameNetworkPortalConnectionDelegate {
    func foundHostsChanged(foundHosts: [MCPeerID]) {
        hosts = foundHosts
        dispatch_async(dispatch_get_main_queue(), {
            self.roomsAvailableTableView.reloadData()
        })
    }
    
    func playerWantsToJoinRoom(peer: MCPeerID, acceptGuest: (Bool) -> Void) {
        
    }
    
    func playersInRoomChanged(peerIDs: [MCPeerID]) {
        
    }
    
    func disconnectedFromRoom() {
        
    }
    
    func gameStartSignalReceived(data: AnyObject?, peer: MCPeerID) {
        
    }
    
    func connectedToRoom(peer: MCPeerID) {
        performSegueWithIdentifier("enterRoomSegue", sender: self)
    }
}
