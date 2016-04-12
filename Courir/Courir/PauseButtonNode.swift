//
//  PauseButtonNode.swift
//  Courir
//
//  Created by Ian Ngiaw on 4/2/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

protocol PauseButtonDelegate: class {
    func pauseButtonTouched()
}

class PauseButtonNode: SKLabelNode {
    weak var delegate: PauseButtonDelegate?
    
    override init() {
        super.init()
        text = "PAUSE"
        fontName = "Raleway-ExtraLight"
        fontSize = 25
        userInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        delegate?.pauseButtonTouched()
    }
}