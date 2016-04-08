//
//  Constants.swift
//  Courir
//
//  Created by Karen Ang on 19/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import SpriteKit
import MultipeerConnectivity

// Grid sizes for calculation of screen coordinates from world coordinates
let gameGridSize = 32
let actualGridSize = 1024
let unitsPerGameGridCell: Int = actualGridSize / gameGridSize

// Length of countdown timer
let countdownTimerStart = 3

// Probabilities of obstacles appearing
let floatingProbability = Float(0.05)
let nonfloatingProbability = Float(0.05)

let obstacleSpaceMultiplier = 1.5

let initialGameSpeed = 1
let speedMultiplier = 3.5

let framerate = 30
let jumpTimeSteps = 15
let duckTimeSteps = 15
let invulnerableTimeSteps = 15

let jumpDuration = Double(jumpTimeSteps) / Double(framerate)
let duckDuration = Double(duckTimeSteps) / Double(framerate)

// Textures
let textureAtlases = [playerRunningAtlas, playerJumpingAtlas, playerDuckingAtlas,
                      playerStationaryAtlas, plumbobAtlas, digitsAtlas]
let playerRunningAtlas = SKTextureAtlas(named: "PlayerRunning")
let playerJumpingAtlas = SKTextureAtlas(named: "PlayerJumping")
let playerDuckingAtlas = SKTextureAtlas(named: "PlayerDucking")
let playerStationaryAtlas = SKTextureAtlas(named: "PlayerStationary")
let plumbobAtlas = SKTextureAtlas(named: "Plumbob")
let digitsAtlas = SKTextureAtlas(named: "Digits")

// My Details
var myName: String?
let myDeviceName = UIDevice.currentDevice().name
let myDefaultPlayerNumber = 1
let myMultiplayerModeNumber = 0
let myPeerID = MCPeerID(displayName: myName ?? myDeviceName)
