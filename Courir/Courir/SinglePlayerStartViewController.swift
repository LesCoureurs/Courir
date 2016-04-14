//
//  SinglePlayerStartViewController.swift
//  Courir
//
//  Created by Ian Ngiaw on 4/5/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit
import MultipeerConnectivity

private let cellIdentifier = "previousRunCell"

class SinglePlayerStartViewController: UIViewController {

    private lazy var dateFormatter: NSDateFormatter = {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd-MMM-yyyy hh:mm:ss a"
        return dateFormatter
    }()
    
    @IBOutlet weak var previousRunTableView: UITableView!
    var ghostStoreDates = GhostStore.storedGhostDates
    var selectedGhostStore: GhostStore?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        previousRunTableView.dataSource = self
        previousRunTableView.delegate = self
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destination = segue.destinationViewController as? GameViewController where segue.identifier == "startNewGameSegue" || segue.identifier == "startGhostGameSegue" {
            let singlePlayerData = GameSetupData(mode: .SinglePlayer, host: nil, peers: [MCPeerID](), seed: nil)
            destination.setUpWith(singlePlayerData)

            if segue.identifier == "startGhostGameSegue" {
                destination.initialGhostStore = selectedGhostStore
            }
        }
    }
    
    // MARK: Button press method
    func deleteButtonPressed(sender: UIButton) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let row = sender.tag
            let date = self.ghostStoreDates[row]
            GhostStore.removeGhostData(forDate: date) {
                (complete) in
                if complete {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.ghostStoreDates.removeAtIndex(row)
                        self.previousRunTableView.reloadData()
                    }
                }
            }
        }
    }
}

extension SinglePlayerStartViewController: UITableViewDataSource {
    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView
            .dequeueReusableCellWithIdentifier(cellIdentifier) as! PreviousRunTableViewCell
        let date = ghostStoreDates[indexPath.row]
        if let ghostStore = GhostStore.init(date: date) {
            let score = ghostStore.score
            cell.infoLabel.text = "\(dateFormatter.stringFromDate(date)) Score: \(score)"
        }
        cell.deleteButton.tag = indexPath.row
        cell.deleteButton.addTarget(self, action: #selector(deleteButtonPressed(_:)),
                                    forControlEvents: .TouchUpInside)
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ghostStoreDates.count
    }
}

extension SinglePlayerStartViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let date = self.ghostStoreDates[indexPath.row]
            if let ghostStore = GhostStore(date: date) {
                self.selectedGhostStore = ghostStore
                dispatch_async(dispatch_get_main_queue()) {
                    self.performSegueWithIdentifier("startGhostGameSegue", sender: self)
                }
            }
        }
    }
}