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

    private var isProcessingTransition = false

    override func viewDidLoad() {
        super.viewDidLoad()
        loadMenuBg()
        let menuVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier(Screen.Menu.rawValue)
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

    func prepareForTransitionInto(newScreen: Screen) -> UIViewController? {
        guard !isProcessingTransition else {
            return nil
        }

        let newVCIdentifier = newScreen.rawValue
        if let newVC = storyboard?.instantiateViewControllerWithIdentifier(newVCIdentifier) {
            isProcessingTransition = true
            return newVC
        }
        return nil
    }

    func completeTransition(to newVC: UIViewController, from oldVC: UIViewController) {
        if isProcessingTransition {
            viewControllerStack.append(newVC)
            cycleFromViewController(oldVC, to: newVC)
            isProcessingTransition = false
        }
    }

    func transitionInto(newScreen: Screen, from oldVC: UIViewController) {
        guard !isProcessingTransition else {
            return
        }

        let newVCIdentifier = newScreen.rawValue
        if let newVC = storyboard?.instantiateViewControllerWithIdentifier(newVCIdentifier) {
            viewControllerStack.append(newVC)
            cycleFromViewController(oldVC, to: newVC)
        }
    }

    func transitionOut() {
        guard !isProcessingTransition else {
            return
        }
        
        if let oldVC = viewControllerStack.last {
            transitionOut(from: oldVC, downLevels: 1)
        }
    }

    func transitionOut(from oldVC: UIViewController, downLevels times: Int) {
        guard !isProcessingTransition else {
            return
        }

        for _ in 0..<times {
            viewControllerStack.popLast()
        }

        if let newVC = viewControllerStack.last {
            cycleFromViewController(oldVC, to: newVC)
        }
    }

    private func cycleFromViewController(oldVC: UIViewController, to newVC: UIViewController) {
        oldVC.willMoveToParentViewController(nil)
        addChildViewController(newVC)

        transitionFromViewController(oldVC, toViewController: newVC, duration: 0.2, options: .TransitionCrossDissolve, animations: nil, completion: { _ in
            oldVC.removeFromParentViewController()
            newVC.didMoveToParentViewController(self) })
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
            contentView.addSubview(viewController.view)
            viewController.didMoveToParentViewController(self)
        }
    }    
}

