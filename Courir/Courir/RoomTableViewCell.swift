//
//  RoomTableViewCell.swift
//  Courir
//
//  Created by Sebastian Quek on 14/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit

class RoomTableViewCell: UITableViewCell {
    
    @IBOutlet weak var hostName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgroundColor = UIColor.clearColor()
        let selectedView = UIView(frame: frame)
        selectedView.backgroundColor = selectedCellColor
        selectedBackgroundView = selectedView
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
