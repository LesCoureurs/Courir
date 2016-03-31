//
//  GameEndView
//  Courir
//
//  Created by Hieu Giang on 30/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit

class GameEndView: UIView {
    var scoreSheet: [Int: [String: AnyObject]]?
    let numCol = 2
    let numRows = 4
    let resultTable: UITableView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        resultTable = UITableView()
        resultTable.dataSource = self
        resultTable.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GameEndView: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numRows
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        <#code#>
    }
}

extension GameEndView: UITableViewDelegate {
    
}