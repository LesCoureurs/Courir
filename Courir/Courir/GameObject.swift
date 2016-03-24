//
//  GameObject.swift
//  Courir
//
//  Created by Sebastian Quek on 19/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit

protocol GameObject: Observed {
    var xWidth: Int { get }
    var yWidth: Int { get }
    var xCoordinate: Int { get set }
    var yCoordinate: Int { get set }
}
