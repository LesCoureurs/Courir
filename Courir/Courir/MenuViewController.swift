//
//  MenuViewController.swift
//  Courir
//
//  Created by Karen Ang on 19/3/16.
//  Copyright (c) 2016 NUS CS3217. All rights reserved.
//

import UIKit
import SpriteKit
import MultipeerConnectivity

class MenuViewController: UIViewController {
    private var saveAction: UIAlertAction?
    
    private let menuOptions = ["Play", "Multiplayer"]
    @IBOutlet var menuButtons: [UIButton]!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        if myName == nil {
            askForName()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    @IBAction func handleExitGame(sender: UIStoryboardSegue) {
        
    }

    @IBAction func unwindToMenuFromRoomSelection(sender: UIStoryboardSegue) {
        
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "startGameSegue" {
            let destination = segue.destinationViewController as! GameViewController
            let singlePlayerData = GameSetupData(mode: .SinglePlayer, host: nil, peers: [MCPeerID](), seed: nil)
            destination.setUpWith(singlePlayerData)
        }
    }
    
    // MARK: Player Name
    private func askForName() {
        let title = "Enter Name"
        let message = ""
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        var nameTextField: UITextField?
        
        alertController.addTextFieldWithConfigurationHandler({ (textField) -> Void in
            textField.placeholder = myDeviceName
            nameTextField = textField
            nameTextField!.addTarget(self, action: #selector(MenuViewController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            alertController.dismissViewControllerAnimated(true, completion: nil)
        }
        alertController.addAction(cancelAction)
        
        saveAction = UIAlertAction(title: "Save", style: .Default) { action -> Void in
            myName = nameTextField?.text
        }
        
        alertController.addAction(saveAction!)
        disableSaveIfEmptyField(nameTextField!)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func textFieldDidChange(textField: UITextField) {
        disableSaveIfEmptyField(textField)
    }
    
    private func disableSaveIfEmptyField(textField: UITextField) {
        guard let textContent = textField.text else {
            return
        }
        saveAction!.enabled = !textContent.isEmpty
    }
}
