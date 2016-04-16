//
//  GameEndTableCell
//  Courir
//
//  Created by Hieu Giang on 31/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit

class GameEndTableCell: UITableViewCell {
    @IBOutlet weak var indexNum: UILabel!
    @IBOutlet weak var playerNameLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgroundColor = UIColor.clearColor()
        
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
