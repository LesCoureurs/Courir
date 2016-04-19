//
//  SettingsManager.swift
//  Courir
//
//  Created by Karen on 6/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import Foundation

class SettingsManager {
    static let _instance = SettingsManager()
    static let nameKey = "myName"
    private static let defaults = NSUserDefaults.standardUserDefaults()

    private init() {}

    func get(key: String) -> AnyObject? {
        return SettingsManager.defaults.objectForKey(key)
    }

    func put(key: String, value: AnyObject) {
        SettingsManager.defaults.setObject(value, forKey: key)
    }
}