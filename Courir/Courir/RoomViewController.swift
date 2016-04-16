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

private let cellIdentifier = "peerCell"

class RoomViewController: UIViewController {

    static let numberOfVCsToMenu = 2

    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var peersTableView: UITableView!

    private var seed: NSData?

    private(set) var mode: GameMode = .Multiplayer
    private(set) var isHost = true
    var host: MCPeerID? = myPeerID
    
    private var peers = [MCPeerID]()

    private var gameSetupData: GameSetupData {
        return GameSetupData(mode: mode, host: host, peers: peers, seed: seed)
    }

    private let portal = GameNetworkPortal._instance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        portal.connectionDelegate = self
        peersTableView.dataSource = self

        startButton.setLetterSpacing(defaultLetterSpacing)
        
        if isHost {
            portal.beginHosting()
            startButton.enabled = peers.count > 0
        } else {
            startButton.enabled = false
        }
        
        dispatch_semaphore_signal(portal.semaphore)
    }

    // MARK: Setup

    func playerIsNotHost() {
        isHost = false
        host = nil
    }

    func setMode(mode: GameMode) {
        self.mode = mode
    }

    // MARK: - Navigation

    @IBAction func handleBackAction(sender: AnyObject) {
        portal.disconnectFromRoom()
        if let parentVC = parentViewController as? MainViewController {
            parentVC.transitionOut()
        }
    }
    
    @IBAction func handleStartGameAction(sender: AnyObject) {
        portal.stopHosting()
        portal.stopSearchingForHosts()
        var startData = [String: AnyObject]()
        let seedString = "\(arc4random())"
        seed = seedString.dataUsingEncoding(NSUTF8StringEncoding)
        startData["seed"] = seedString
        startData["mode"] = mode.rawValue
        GameNetworkPortal._instance.send(.GameDidStart, data: startData)
        presentGameScene()
    }

    private func presentGameScene() {
        dispatch_async(dispatch_get_main_queue(), { self.performSegueWithIdentifier("startGameSegue", sender: self) })

    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "startGameSegue" {
            let destination = segue.destinationViewController as! GameViewController
            destination.setUpWith(gameSetupData)
        }
    }
    
    @IBAction func unwindToRoomViewFromGameView(unwindSegue: UIStoryboardSegue) {
        if isHost {
            portal.beginHosting()
        }
    }
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        portal.disconnectFromRoom()
        performSegueWithIdentifier("unwindToRoomSelectionFromRoomViewSegue", sender: self)
    }

    @IBAction func unwindToMenuViaRoomView(sender: UIStoryboardSegue) {
        if let parentVC = parentViewController as? MainViewController {
            parentVC.transitionOut(from: self, downLevels: RoomViewController.numberOfVCsToMenu)
        }
    }
}

extension RoomViewController: UITableViewDataSource {
    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView
            .dequeueReusableCellWithIdentifier(cellIdentifier)! as! PeerTableViewCell
        cell.peerName.text = peers[indexPath.row].displayName
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peers.count
    }
}

extension RoomViewController: GameNetworkPortalConnectionDelegate {
    func foundHostsChanged(foundHosts: [MCPeerID]) {
        print("room view delegate")
    }
    
    func playerWantsToJoinRoom(peer: MCPeerID, acceptGuest: (Bool) -> Void) {
        acceptGuest(true)
    }
    
    func playersInRoomChanged(peerIDs: [MCPeerID]) {
        peers = peerIDs
        
        if isHost {
            dispatch_async(dispatch_get_main_queue()){
                self.startButton.enabled = self.peers.count > 0
            }
        }

        dispatch_async(dispatch_get_main_queue()) {
            self.peersTableView.reloadData()
        }
    }
    
    // When self is disconnected from a room
    func disconnectedFromRoom(peer: MCPeerID) {
        dispatch_async(dispatch_get_main_queue(), {
            if let parentVC = self.parentViewController as? MainViewController {
                parentVC.transitionOut()
            }
        })
    }
    
    func gameStartSignalReceived(data: AnyObject?, peer: MCPeerID) {
        guard let dataDict = data as? [String: AnyObject],
            seed = dataDict["seed"] as? String, modeValue = dataDict["mode"] as? Int, mode = GameMode(rawValue: modeValue) else {
            return
        }
        self.seed = seed.dataUsingEncoding(NSUTF8StringEncoding)
        self.mode = mode

        if mode == .SpecialMultiplayer {
            self.host = peer
        }
        presentGameScene()
    }
    
    func connectedToRoom(peer: MCPeerID) {
        
    }
}