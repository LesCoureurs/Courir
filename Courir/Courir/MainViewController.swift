//
//  MainViewController.swift
//  Courir
//
//  Created by Karen on 13/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//
import Foundation
import UIKit
import SwiftyGif

class MainViewController: UIViewController {

    // MARK: Properties

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var menuBackground: UIImageView!

    private var viewControllerStack = [UIViewController]()
    private var isProcessingTransition = false

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        loadMenuBackground()
        let menuVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier(Screen.Menu.rawValue)
        updateActiveViewController(menuVC)
        viewControllerStack.append(menuVC)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func loadMenuBackground() {
        let gifManager = SwiftyGifManager(memoryLimit: 200)
        let backgroundGif = UIImage(gifName: "menu-bg")
        menuBackground.setGifImage(backgroundGif, manager: gifManager)
    }

    // MARK: Segues

    /**
     Notifies the `MainViewController` that a segue into `newScreen` is about to be
     performed. 

     - important:
     The `MainViewController` must subsequently be called with `completeTransition`
     instead of `transitionInto`.
     
     - returns:
     The UIViewController for the new screen
     */

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

    /**
     Completes the transition into the specified new view controller. This
     function complements `prepareForTransitionInto`.
     */

    func completeTransition(to newVC: UIViewController, from oldVC: UIViewController) {
        if isProcessingTransition {
            viewControllerStack.append(newVC)
            cycleFromViewController(oldVC, to: newVC)
            isProcessingTransition = false
        }
    }

    /**
     Transition *immediately* into the specified screen. The `MainViewController`
     should not be in the middle of preparing for a transition.
     */

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

    /**
     Transition *immediately* out into previous screen the user was at.
     This is a convenience method.
     */

    func transitionOut() {
        guard !isProcessingTransition else {
            return
        }
        
        if let oldVC = viewControllerStack.last {
            transitionOut(from: oldVC, downLevels: 1)
        }
    }

    /**
     Transition out from the specified view controller by the specified number.
     
     - parameters:
        - from/oldVC: The current view controller which you wish to transition out from
        - downLevels/times: The number of levels to go back, e.g. for a stack of
          `[A, B]`, transitioning out 1 time from B means the screen is now at A
     */

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

