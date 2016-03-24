//
//  Observer.swift
//  Courir
//
//  Created by Sebastian Quek on 24/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

protocol Observer : class {
    func didChangeProperty(propertyName: String, from: AnyObject?)
}

protocol Observed {
    weak var observer: Observer? { get set }
}