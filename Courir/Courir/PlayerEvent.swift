//
//  PlayerEvent.swift
//  Courir
//
//  Created by Ian Ngiaw on 4/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Foundation

class PlayerEvent: NSObject, NSCoding {
    let event: GameEvent
    let timeStep: Int
    let otherData: AnyObject?
    
    init(event: GameEvent, timeStep: Int, otherData: AnyObject? = nil) {
        self.event = event
        self.timeStep = timeStep
        self.otherData = otherData
    }
    
    required init?(coder aDecoder: NSCoder) {
        event = GameEvent(rawValue: aDecoder.decodeIntegerForKey("eventRawVal"))!
        timeStep = aDecoder.decodeIntegerForKey("timeStepVal")
        otherData = aDecoder.decodeObjectForKey("otherDataVal")
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeInteger(event.rawValue, forKey: "eventRawVal")
        coder.encodeInteger(timeStep, forKey: "timeStepVal")
        coder.encodeObject(otherData, forKey: "otherDataVal")
    }
}