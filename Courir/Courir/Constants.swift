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

let obstacleSpaceMultiplier = 1.2

let initialGameSpeed = 1
let speedMultiplier = 10.0

let framerate = 30.0
let tickInterval = 1.0/framerate
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

let numEnvironmentObjects = 3

// My Details
let me = MyPlayer()
let myDeviceName = me.deviceName
let myPeerID = me.peerID
let defaultHostNumber = 3

// Colors
let blue = UIColor(red: 95, green: 174, blue: 190)
let brown = UIColor(red: 73, green: 60, blue: 48)
let selectedCellColor = UIColor(white: 1, alpha: 0.2)
