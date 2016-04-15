//
//  RoomSelectionViewController.swift
//  Courir
//
//  Created by Ian Ngiaw on 3/25/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit
import MultipeerConnectivity

private let cellIdentifier = "roomCell"

class RoomSelectionViewController: UIViewController {
    
    @IBOutlet weak var roomsAvailableTableView: UITableView!
    @IBOutlet weak var newRoomButton: UIButton!
    
    var hosts = [MCPeerID]()
    
    let portal = GameNetworkPortal._instance

    override func viewDidLoad() {
        super.viewDidLoad()
        roomsAvailableTableView.delegate = self
        roomsAvailableTableView.dataSource = self
        
        newRoomButton.setLetterSpacing(defaultLetterSpacing)
    }
    
    @IBAction func refreshButtonPressed(sender: UIButton) {
        // TODO: Add logic for refresh button
    }

    // MARK: - Navigation

    @IBAction func handleNewRoomAction(sender: AnyObject) {
        if let parentVC = parentViewController as? MainViewController {
            parentVC.transitionInto(.Room, from: self)
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
    
    @IBAction func handleBackAction(sender: AnyObject) {
        if let parentVC = parentViewController as? MainViewController {
            parentVC.transitionOut()
        }
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
        if let parentVC = parentViewController as? MainViewController, newVC = parentVC.prepareForTransitionInto(.Room) as? RoomViewController {
            newVC.playerIsNotHost()
            parentVC.completeTransition(to: newVC, from: self)
        }
    }
}

extension RoomSelectionViewController: UITableViewDataSource {
    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView
            .dequeueReusableCellWithIdentifier(cellIdentifier)! as! RoomTableViewCell
        cell.hostName.text = hosts[indexPath.row].displayName
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
