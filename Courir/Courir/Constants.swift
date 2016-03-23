//
//  Constants.swift
//  Courir
//
//  Created by Karen Ang on 19/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

let gameGridSize = 32
let actualGridSize = 1024
let unitsPerGameGridCell: Int = actualGridSize / gameGridSize

let initialGameSpeed = 1
let speedMultiplier = 0.337768 * 5

let floatingProbability = Float(0.25)
let nonfloatingProbability = Float(0.25)

let framerate = 60
let jumpTimeSteps = 36
let duckTimeSteps = 36

let jumpDuration = Double(jumpTimeSteps) / Double(framerate)
let duckDuration = Double(jumpTimeSteps) / Double(framerate)
let invulnerableDuration = 1.0

let playerJumpTexture = SKTexture(imageNamed: "iso_player_jump")
let playerDuckTexture = SKTexture(imageNamed: "iso_player_duck")
let playerTexture = SKTexture(imageNamed: "iso_player")

let resetPlayerTexture = SKAction.setTexture(playerTexture)