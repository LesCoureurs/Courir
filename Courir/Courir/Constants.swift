//
//  Constants.swift
//  Courir
//
//  Created by Karen Ang on 19/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

// Grid sizes for calculation of screen coordinates from world coordinates
let gameGridSize = 32
let actualGridSize = 1024
let unitsPerGameGridCell: Int = actualGridSize / gameGridSize

// Probabilities of obstacles appearing
let floatingProbability = Float(0.25)
let nonfloatingProbability = Float(0.25)

let obstacleSpaceMultiplier = 1.5

let initialGameSpeed = 1
let speedMultiplier = 0.337768 * 5

let framerate = 60
let jumpTimeSteps = 54
let duckTimeSteps = 54
let invulnerableTimeSteps = 54

let jumpDuration = Double(jumpTimeSteps) / Double(framerate)
let duckDuration = Double(jumpTimeSteps) / Double(framerate)

// For calculation of player's position when jumping
let maxJumpHeight = -CGFloat(3 * unitsPerGameGridCell)
// acceleration to reach max height in duration a = 4x/t^2
let acceleration = 4 * maxJumpHeight / (CGFloat(jumpDuration) * CGFloat(jumpDuration))
// initial velocity to reach max height in duration v = -at/2
let velocity = -CGFloat(jumpDuration) * acceleration / 2

// Textures
let playerJumpTexture = SKTexture(imageNamed: "iso_player_jump")
let playerDuckTexture = SKTexture(imageNamed: "iso_player_duck")
let playerTexture = SKTexture(imageNamed: "iso_player")
let obstacleNonFloatingTexture = SKTexture(imageNamed: "iso_non_floating_obstacle")
let obstacleFloatingTexture = SKTexture(imageNamed: "iso_floating_obstacle")

// My Details
let myDeviceName = UIDevice.currentDevice().name
let myDefaultPlayerNumber = 1
let myMultiplayerModeNumber = 0
