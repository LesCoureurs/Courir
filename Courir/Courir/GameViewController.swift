//
//  GameViewController.swift
//  Courir
//
//  Created by Karen on 25/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit
import SpriteKit
import MultipeerConnectivity

class GameViewController: UIViewController {

    var isMultiplayer = false
    var peers = [MCPeerID]()
    var seed: NSData?
    var initialGhostStore: GhostStore?
    var gameEndGhostStore: GhostStore?
    
    private let portal = GameNetworkPortal._instance

    @IBOutlet weak var endGameLabel: UILabel!
    @IBOutlet weak var endGameMenu: GameEndView!
    @IBOutlet weak var endGameTable: UITableView!
    @IBOutlet weak var replayOrUnwindButton: UIButton!
    @IBOutlet weak var saveRunButtton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(self.receiveEvent(_:)),
                                                         name: "showEndGameMenu", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(self.exitGame),
                                                         name: "exitGame", object: nil)
        setUpGameEndMenu()
        presentGameScene()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    private func presentGameScene() {
        let gameScene = GameScene(size: view.bounds.size)
        gameScene.initialGhostStore = initialGhostStore
        gameScene.isMultiplayer = isMultiplayer
        gameScene.peers = peers
        gameScene.seed = seed
        let skView = self.view as! SKView!
        skView.ignoresSiblingOrder = true
        gameScene.scaleMode = .AspectFill
        skView.presentScene(gameScene)
    }
    
    func exitGame() {
        performSegueWithIdentifier("exitGameSegue", sender: self)
    }

    func receiveEvent(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        guard let eventRawValue = userInfo["eventRawValue"] as? Int,
            gameResult = userInfo["gameResult"] as? [MCPeerID: Int],
            ghostStore = userInfo["ghostStore"] as? GhostStore else {
            return
        }
        
        var gameResultArray = [(peerID: MCPeerID, score: Int)]()
        gameEndGhostStore = ghostStore
        
        for (key, value) in gameResult {
            gameResultArray.append((peerID: key, score: value))
        }
        
        gameResultArray.sortInPlace({ $0.score > ($1.score) })
        
        if let event = GameEvent(rawValue: eventRawValue) {
            switch event {
            case .GameDidEnd:
                dispatch_async(dispatch_get_main_queue()) {
                    self.displayGameEndMenu(gameResultArray)
                }
            default:
                break
            }
        }
    }
    
    private func setUpGameEndMenu() {
        let title = isMultiplayer ? "Back To Room" : "Play Again"
        replayOrUnwindButton.setTitle(title, forState: .Normal)
        
        endGameTable.dataSource = endGameMenu
        endGameTable.delegate = endGameMenu
        endGameMenu.hidden = true
        endGameMenu.alpha = 0
        endGameMenu.layer.cornerRadius = 10
    }
    
    private func displayGameEndMenu(gameResultArray: [(peerID: MCPeerID, score: Int)]) {
        endGameMenu.hidden = false
        endGameMenu.scoreSheet = gameResultArray
        endGameTable.reloadData()

        endGameLabel.text = "Game Over"
        
        UIView.animateWithDuration(0.5) { () -> Void in
            self.endGameMenu.alpha = 1
        }
    }
    
    @IBAction func mainMenuButtonPressed(sender: AnyObject) {
        if isMultiplayer {
            portal.disconnectFromRoom()
        }
        performSegueWithIdentifier("exitGameSegue", sender: self)
    }
    
    @IBAction func saveRunButtonPressed(sender: AnyObject) {
        guard let ghostStore = gameEndGhostStore else {
            return
        }
        saveRunButtton.enabled = false
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            ghostStore.storeGhostData(nil)
        }
    }
    
    @IBAction func replayOrUnwindButtonPressed(sender: AnyObject) {
        if isMultiplayer {
            performSegueWithIdentifier("unwindToRoomViewFromGameView", sender: self)
        } else {
            initialGhostStore = gameEndGhostStore
            setUpGameEndMenu()
            presentGameScene()
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
