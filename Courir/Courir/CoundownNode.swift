//
//  CoundownNode.swift
//  Courir
//
//  Created by Ian Ngiaw on 4/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

protocol CountdownDelegate: class {
    func didCountdownEnd()
}

class CountdownNode: SKLabelNode {
    private var coundownStartTimeInterval: CFTimeInterval?
    weak var delegate: CountdownDelegate?
    
    override init() {
        super.init()
        text = "\(countdownTimerStart)"
        fontName = "HelveticaNeue-Bold"
        fontSize *= 3
        fontColor = UIColor.blackColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateCountdownTime(currentTime: CFTimeInterval) {
        if let start = coundownStartTimeInterval {
            let timeSinceStart = Int(currentTime - start)
            let countdownValue = countdownTimerStart - timeSinceStart
            if countdownValue > 0 {
                text = "\(countdownValue)"
            } else {
                removeFromParent()
                delegate?.didCountdownEnd()
            }
        } else {
            coundownStartTimeInterval = currentTime
        }
    }
    
    func reset() {
        coundownStartTimeInterval = nil
        text = "\(countdownTimerStart)"
    }
}