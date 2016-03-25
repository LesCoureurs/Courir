//
//  MenuViewController.swift
//  Courir
//
//  Created by Karen Ang on 19/3/16.
//  Copyright (c) 2016 NUS CS3217. All rights reserved.
//

import UIKit
import SpriteKit

class MenuViewController: UIViewController {

    private let menuOptions = ["Play", "Multiplayer"]
    @IBOutlet var menuButtons: [UIButton]!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    @IBAction func handleSinglePlayerStart(sender: AnyObject) {
        performSegueWithIdentifier("startGameSegue", sender: self)
    }

    @IBAction func handleMultiplayerStart(sender: AnyObject) {
        performSegueWithIdentifier("selectRoomSegue", sender: self)
    }

    @IBAction func handleExitGame(sender: UIStoryboardSegue) {
        
    }

     // MARK: - Navigation

     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "startGameSegue" {
            let destination = segue.destinationViewController as! GameViewController
            destination.isMultiplayer = false
        }
     }
}
