//
//  Player.swift
//  Courir
//
//  Created by Sebastian Quek on 19/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit

enum PlayerState: Int {
    case Stationary, Running, Jumping, Ducking
}

class Player: GameObject {
    private(set) var xWidth = 4
    private(set) var yWidth = 4
    
    var xCoordinate: Int
    var yCoordinate: Int
    
    var state = PlayerState.Stationary
    
    init(xCoordinate x: Int, yCoordinate y: Int) {
        self.xCoordinate = x
        self.yCoordinate = y
    }
    
    func fallBehind() {
        xCoordinate -= 1
    }
    
    func run() {
        state = .Running
    }
    
    func jump() {
        state =  .Jumping
    }
    
    func duck() {
        state = .Ducking
    }
}