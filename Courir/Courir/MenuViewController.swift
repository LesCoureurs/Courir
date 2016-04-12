//
//  MenuViewController.swift
//  Courir
//
//  Created by Karen Ang on 19/3/16.
//  Copyright (c) 2016 NUS CS3217. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

class MenuViewController: UIViewController {
    private var saveAction: UIAlertAction?
    
    @IBOutlet var menuButtons: [UIButton]!
    @IBOutlet var menuBg: UIWebView!
    
    private let buttonTitles = ["PLAY", "MULTIPLAYER", "SETTINGS"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadMenuBg()
        for (button, title) in zip(menuButtons, buttonTitles) {
            button.setAttributedTitle(CourirUINodes.generateAttributedString(title, UIColor.whiteColor()),
                                      forState: UIControlState.Normal)
        }
    }
    
    private func loadMenuBg() {
        let filePath = NSBundle.mainBundle().pathForResource("menu-bg", ofType: "gif")
        let menuBgGif = NSData(contentsOfFile: filePath!)
        menuBg.loadData(menuBgGif!, MIMEType: "image/gif", textEncodingName: String(), baseURL: NSURL())
        menuBg.userInteractionEnabled = false;
    }
    
    override func viewDidAppear(animated: Bool) {
        if me.name == nil {
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

    @IBAction func unwindToMenu(sender: UIStoryboardSegue) {
        
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "startGameSegue" {
            let destination = segue.destinationViewController as! GameViewController
            destination.isMultiplayer = false
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
            if let value = nameTextField?.text {
                SettingsManager._instance.put("myName", value: value)
            }
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
