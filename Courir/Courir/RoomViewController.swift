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
        peersTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        portal.connectionDelegate = self
        peersTableView.dataSource = self
        
        if isHost {
            portal.beginHosting()
            startButton.enabled = peers.count > 0
        } else {
            startButton.enabled = false
        }
    }

    @IBAction func startGame(sender: AnyObject) {
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
    
    func playerIsNotHost() {
        isHost = false
        host = nil
    }

    func setMode(mode: GameMode) {
        self.mode = mode
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
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
    func disconnectedFromRoom() {
        dispatch_async(dispatch_get_main_queue(), {
            self.performSegueWithIdentifier("unwindToRoomSelectionFromRoomViewSegue", sender: self)
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