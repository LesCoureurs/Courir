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

let initialGameSpeed = 60
let jumpDistance = 10 * unitsPerGameGridCell
let duckDistance = 10 * unitsPerGameGridCell
let invulnerableDistance = 10 * unitsPerGameGridCell

let speedMultiplier = 0.337768 * 7

let playerJumpTexture = SKTexture(imageNamed: "iso_player_jump")
let playerDuckTexture = SKTexture(imageNamed: "iso_player_duck")
let playerTexture = SKTexture(imageNamed: "iso_player")

let resetPlayerTexture = SKAction.setTexture(playerTexture)