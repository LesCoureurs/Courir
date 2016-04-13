//
//  MainViewController.swift
//  Courir
//
//  Created by Karen on 13/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//
import Foundation
import UIKit

class MainViewController: UIViewController {

    @IBOutlet var menuBg: UIWebView!
    @IBOutlet weak var contentView: UIView!

    private var viewControllerStack = [UIViewController]()

    override func viewDidLoad() {
        super.viewDidLoad()
        loadMenuBg()
        let menuVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier(Screen.Main.rawValue)
        updateActiveViewController(menuVC)
        viewControllerStack.append(menuVC)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func loadMenuBg() {
        let filePath = NSBundle.mainBundle().pathForResource("menu-bg", ofType: "gif")
        let menuBgGif = NSData(contentsOfFile: filePath!)
        menuBg.loadData(menuBgGif!, MIMEType: "image/gif", textEncodingName: String(), baseURL: NSURL())
        menuBg.userInteractionEnabled = false;
    }

    func transitionInto(newScreen: Screen, from oldVC: UIViewController) {
        let newVCIdentifier = newScreen.rawValue
        if let newVC = storyboard?.instantiateViewControllerWithIdentifier(newVCIdentifier) {
            viewControllerStack.append(newVC)
            cycleFromViewController(oldVC, to: newVC)
        }
    }

    func transitionOut() {
        if let top = viewControllerStack.popLast() {
            removeActiveViewController(top)
            updateActiveViewController(viewControllerStack.last)
        }
    }

    private func cycleFromViewController(oldVC: UIViewController, to newVC: UIViewController) {
        oldVC.willMoveToParentViewController(nil)
        addChildViewController(newVC)

        transitionFromViewController(oldVC, toViewController: newVC, duration: 0, options: .TransitionNone, animations: nil, completion: nil)
    }

    private func removeActiveViewController(oldViewController: UIViewController?) {
        if let viewController = oldViewController {
            viewController.willMoveToParentViewController(nil)
            viewController.view.removeFromSuperview()
            viewController.removeFromParentViewController()
        }
    }

    private func updateActiveViewController(newViewController: UIViewController?) {
        if let viewController = newViewController {
            addChildViewController(viewController)
            viewController.view.frame = contentView.bounds
            self.contentView.addSubview(viewController.view)
            viewController.didMoveToParentViewController(self)
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

