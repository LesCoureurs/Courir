//
//  Player.swift
//  Courir
//
//  Created by Sebastian Quek on 19/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit

class Player: GameObject {
    static let defaultHeight = 128
    static let defaultWidth = 32
    static let heightWhenJumping = 100
    static let heightWhenDucking = 64
    
    private(set) var height = Player.defaultHeight
    private(set) var width = Player.defaultWidth
    
    var xCoordinate: CGFloat
    var yCoordinate: CGFloat
    var speed = CGFloat(10)
    
    init(xCoordinate x: CGFloat, yCoordinate y: CGFloat) {
        self.xCoordinate = x
        self.yCoordinate = y
    }
    
    func updateSpeed(newSpeed: CGFloat) {
        speed = newSpeed
    }
    
    func jump() {
        height = Player.heightWhenJumping
    }
    
    func duck() {
        height = Player.heightWhenDucking
    }
    
    func run() {
        height = Player.defaultHeight
    }
}