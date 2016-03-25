//
//  GameViewController.swift
//  Courir
//
//  Created by Karen Ang on 19/3/16.
//  Copyright (c) 2016 NUS CS3217. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.receiveEvent(_:)), name: "showAlert", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.selectRooms), name: "selectRooms", object: nil)

        presentMenuScene()
    }

    func presentMenuScene() {
        let scene = MenuScene(size: view.bounds.size)
        scene.scaleMode = .ResizeFill

        let skView = self.view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true

        skView.presentScene(scene)
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func selectRooms() {
        performSegueWithIdentifier("selectRoomSegue", sender: self)
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

        let okAction = UIAlertAction(title: "Ok", style: .Default, handler: { (_) in self.presentMenuScene() })
        alertController.addAction(okAction)
        return alertController
    }
}
