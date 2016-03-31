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
    var seed: String?

    @IBOutlet weak var endGameLabel: UILabel!
    @IBOutlet weak var endGameMenu: GameEndView!
    @IBOutlet weak var endGameTable: UITableView!
    @IBOutlet weak var replayOrUnwindButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpGameEndMenu()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.receiveEvent(_:)), name: "showEndGameMenu", object: nil)
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
        gameScene.isMultiplayer = isMultiplayer
        gameScene.peers = peers
        gameScene.seed = seed
        let skView = self.view as! SKView!
        skView.ignoresSiblingOrder = true
        gameScene.scaleMode = .AspectFill
        skView.presentScene(gameScene)
    }

    func receiveEvent(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        guard let eventRawValue = userInfo["eventRawValue"] as? Int else {
            return
        }
        
        guard let gameResult = userInfo["gameResult"] as? [MCPeerID: Int] else {
            return
        }
        
        var gameResultArray = [(peerID: MCPeerID, score: Int)]()
        
        for (key, value) in gameResult {
            gameResultArray.append((peerID: key, score: value))
        }
        
        gameResultArray.sortInPlace({ $0.score > ($1.score) })
        
        if let event = GameEvent(rawValue: eventRawValue) {
            switch event {
            case .GameDidEnd:
                displayGameEndMenu(gameResultArray)
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

        if gameResultArray.first?.peerID == myPeerID {
            endGameLabel.text = "You won!"
        } else {
            endGameLabel.text = "Ouch!"
        }
        
        UIView.animateWithDuration(0.5) { () -> Void in
            self.endGameMenu.alpha = 1
        }
    }

    @IBAction func replayOrUnwindButtonPressed(sender: AnyObject) {
        if isMultiplayer {
            
        } else {
            
        }
    }
    
    private func createAlertControllerForGameOver(withScore score: Int) -> UIAlertController {
        let title = "Game Over!"
        let message = "Score: \(score)"
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)

        let okAction = UIAlertAction(title: "Ok", style: .Default, handler: { (_) in self.performSegueWithIdentifier("exitGameSegue", sender: self) })
        alertController.addAction(okAction)
        return alertController
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
