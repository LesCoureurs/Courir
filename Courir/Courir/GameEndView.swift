//
//  GameEndView
//  Courir
//
//  Created by Hieu Giang on 30/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class GameEndView: UIView {
    var scoreSheet: [(peerID: MCPeerID, score: Int)]?
    private let numRows = 4
    private let cellIdentifier = "endGameTableCell"
}

extension GameEndView: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numRows
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! GameEndTableCell
        let rank = indexPath.row
        
        guard rank < scoreSheet?.count else {
            return cell
        }
        
        if let entry = scoreSheet?[rank] {
            cell.indexNum.text = rank.orderFormat()
            cell.playerNameLabel.text = entry.peerID.displayName
            cell.scoreLabel.text = String(entry.score)
        }

        return cell
    }
}

extension GameEndView: UITableViewDelegate {
    
}

extension Int {
    func orderFormat() -> String {
        switch(self) {
        case 0: return "1st"
        case 1: return "2nd"
        case 2: return "3rd"
        case 3: return "4th"
        default: return "Error"
        }
    }
}