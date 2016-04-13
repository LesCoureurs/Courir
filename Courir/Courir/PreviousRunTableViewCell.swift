//
//  PreviousRunTableViewCell.swift
//  Courir
//
//  Created by Ian Ngiaw on 4/5/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit

class PreviousRunTableViewCell: UITableViewCell {
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!

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
