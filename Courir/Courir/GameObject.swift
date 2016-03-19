//
//  GameObject.swift
//  Courir
//
//  Created by Sebastian Quek on 19/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit

protocol GameObject {
    var height: Int { get }
    var width: Int { get }
    var xCoordinate: CGFloat { get set }
    var yCoordinate: CGFloat { get set }
}
