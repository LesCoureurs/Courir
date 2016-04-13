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
        roomsAvailableTableView.registerClass(UITableViewCell.self,
                                              forCellReuseIdentifier: cellIdentifier)
        
        portal.connectionDelegate = self
        
        roomsAvailableTableView.delegate = self
        roomsAvailableTableView.dataSource = self
        
        portal.beginSearchingForHosts()
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let roomViewController = segue.destinationViewController as? RoomViewController {
            roomViewController.setMode(.Multiplayer)
            if segue.identifier == "specialModeRoomSegue" {
                roomViewController.setMode(.SpecialMultiplayer)
            } else if segue.identifier == "enterRoomSegue" {
                roomViewController.playerIsNotHost()
            }
        }
    }

    @IBAction func unwindToRoomSelectionFromRoomView(segue: UIStoryboardSegue) {
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

// MARK: UITableViewDelegate
extension RoomSelectionViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        portal.connectToHost(hosts[indexPath.row])
        performSegueWithIdentifier("enterRoomSegue", sender: self)
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
        roomsAvailableTableView.reloadData()
    }
    
    func playerWantsToJoinRoom(peer: MCPeerID, acceptGuest: (Bool) -> Void) {
        
    }
    
    func playersInRoomChanged(peerIDs: [MCPeerID], host: MCPeerID) {
        
    }
    
    func disconnectedFromRoom() {
        
    }
    
    func gameStartSignalReceived(data: AnyObject?, peer: MCPeerID) {
        
    }
}
