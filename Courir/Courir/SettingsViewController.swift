//
//  SettingsViewController.swift
//  Courir
//
//  Created by Karen on 6/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBAction func handleSetName(sender: AnyObject) {
        presentViewController(generateFormFor("New Name", withSaveKey: "myName", andPlaceholder: SettingsManager._instance.get("myName") as! String), animated: true, completion: nil)
    }

    private func generateFormFor(title: String, withSaveKey key: String, andPlaceholder placeholder: String = "") -> UIAlertController {
        let alertController = UIAlertController(title: title, message: "", preferredStyle: .Alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            alertController.dismissViewControllerAnimated(true, completion: nil)
        }
        alertController.addAction(cancelAction)

        let saveAction = UIAlertAction(title: "Save", style: .Default) { _ in
            if let value = alertController.textFields?.first?.text {
                SettingsManager._instance.put(key, value: value)
            }
        }
        alertController.addAction(saveAction)

        alertController.addTextFieldWithConfigurationHandler { textField in
            textField.placeholder = placeholder
            textField.addTarget(self, action: #selector(SettingsViewController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)
        }

        return alertController
        
    }

    func textFieldDidChange(sender: UIControl) {
        if let field = sender as? UITextField, text = field.text, controller = self.presentedViewController as? UIAlertController, save = controller.actions.last {
            save.enabled = !text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).isEmpty
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: - Navigation

    @IBAction func handleBackAction(sender: AnyObject) {
        if let parentVC = parentViewController as? MainViewController {
            parentVC.transitionOut()
        }
    }
}
