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
        super.init(coder: aDecoder)
    }
}

extension EnvironmentSpriteNode: Observer {
    func didChangeProperty(propertyName: String, from: AnyObject?) {
        guard let environment = from as? Environment else {
            return
        }
        dispatch_async(dispatch_get_main_queue()) {
            switch propertyName {
            case "xCoordinate", "yCoordinate":
                self.position = IsoViewConverter.calculateRenderPositionFor(environment)
            case "zPosition":
                self.zPosition = CGFloat(environment.zPosition)
            default:
                return
            }
        }
    }
}