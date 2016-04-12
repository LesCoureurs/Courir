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
    
    private var timer: NSTimer?
    private var countdownValue = countdownTimerStart
    
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
    
//    func updateCountdownTime(currentTime: CFTimeInterval) {
//        if let start = coundownStartTimeInterval {
//            let timeSinceStart = Int(currentTime - start)
//            let countdownValue = countdownTimerStart - timeSinceStart
//            if countdownValue > 0 {
//                text = "\(countdownValue)"
//            } else {
//                removeFromParent()
//                delegate?.didCountdownEnd()
//            }
//        } else {
//            coundownStartTimeInterval = currentTime
//        }
//    }
    
    func start() {
        timer?.invalidate()
        timer = NSTimer(timeInterval: 1.0, target: self,
                        selector: #selector(CountdownNode.timerAction),
                        userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(timer!, forMode: NSRunLoopCommonModes)
    }
    
    func timerAction() {
        countdownValue -= 1
        if countdownValue <= 0 {
            timer?.invalidate()
            removeFromParent()
            delegate?.didCountdownEnd()
            reset()
        } else {
            text = "\(countdownValue)"
            start()
        }
    }
    
    func reset() {
//        coundownStartTimeInterval = nil
        timer?.invalidate()
        removeFromParent()
        countdownValue = countdownTimerStart
        text = "\(countdownTimerStart)"
    }
}