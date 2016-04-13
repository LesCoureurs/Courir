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
    private static let growAndFadeActions =
        SKAction.group([SKAction.scaleTo(2, duration: 1),
                        SKAction.fadeAlphaTo(0.4, duration: 1)])
    private static let resetGrowAndFadeActions =
        SKAction.group([SKAction.scaleTo(1, duration: 0),
                        SKAction.fadeAlphaTo(1, duration: 0)])
    
    weak var delegate: CountdownDelegate?
    
    private var timer: NSTimer?
    private var countdownValue = countdownTimerStart
    
    override init() {
        super.init()
        text = "\(countdownTimerStart)"
        fontName = "Raleway-Bold"
        fontSize *= 3
        fontColor = UIColor.whiteColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func start() {
        timer?.invalidate()
        timer = NSTimer(timeInterval: 1.0, target: self,
                        selector: #selector(CountdownNode.timerAction),
                        userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
        runAction(CountdownNode.growAndFadeActions)
    }
    
    func timerAction() {
        countdownValue -= 1
        if countdownValue <= 0 {
            reset()
            delegate?.didCountdownEnd()
        } else {
            text = "\(countdownValue)"
            runAction(CountdownNode.resetGrowAndFadeActions)
            runAction(CountdownNode.growAndFadeActions)
            start()
        }
    }
    
    func reset() {
        timer?.invalidate()
        removeFromParent()
        countdownValue = countdownTimerStart
        text = "\(countdownTimerStart)"
        runAction(CountdownNode.resetGrowAndFadeActions)
    }
}