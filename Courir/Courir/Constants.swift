//
//  Constants.swift
//  Courir
//
//  Created by Karen Ang on 19/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit

let backgroundImageName = "background"
let gameGridSize = 32
let actualGridSize = 1024
let unitsPerGameGridCell: Int = actualGridSize / gameGridSize

let initialGameSpeed = 1
let gameAcceleration = 0.05
let jumpDistance = 10 * unitsPerGameGridCell
let duckDistance = 10 * unitsPerGameGridCell
let speedMultiplier = 0.337768