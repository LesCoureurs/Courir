//
//  EnvironmentSpriteNode.swift
//  Courir
//
//  Created by Sebastian Quek on 6/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

class EnvironmentSpriteNode: SKSpriteNode {
    static private let defaultScale: CGFloat = 1.05
    
    init(environment: Environment) {
        let texture = SKTexture(imageNamed: "background")
        
        super.init(texture: texture, color: UIColor.clearColor(), size: texture.size())
        environment.observer = self
        
        setScale(EnvironmentSpriteNode.defaultScale)
        position = IsoViewConverter.calculateRenderPositionFor(environment)
        anchorPoint = CGPointMake(0, 0)
        zPosition = CGFloat(environment.zPosition)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EnvironmentSpriteNode: Observer {
    func didChangeProperty(propertyName: String, from: AnyObject?) {
        guard let environment = from as? Environment else {
            return
        }
        
        switch propertyName {
        case "xCoordinate", "yCoordinate":
            position = IsoViewConverter.calculateRenderPositionFor(environment)
        case "zPosition":
            zPosition = CGFloat(environment.zPosition)
        default:
            return
        }
    }
}