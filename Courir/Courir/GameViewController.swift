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
    var seed: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.receiveEvent(_:)), name: "showAlert", object: nil)
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
        let userInfo = notification.userInfo as! [String: Int]
        if let eventRawValue = userInfo["eventRawValue"], event = GameEvent(rawValue: eventRawValue) {
            switch event {
            case .GameDidEnd:
                let score = userInfo["score"] ?? 0
                presentViewController(createAlertControllerForGameOver(withScore: score), animated: true, completion: nil)
            default:
                break
            }
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
