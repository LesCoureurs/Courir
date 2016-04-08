//
//  EnvironmentSpriteNode.swift
//  Courir
//
//  Created by Sebastian Quek on 6/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

class EnvironmentSpriteNode: SKSpriteNode {
    
    init(environment: Environment) {
        let texture = SKTexture(imageNamed: "background")
        
        super.init(texture: texture, color: UIColor.clearColor(), size: texture.size())
        
        setScale(1.05)
        position = IsoViewConverter.calculateRenderPositionFor(environment)
        anchorPoint = CGPointMake(0, 0)
        zPosition = CGFloat(environment.zPosition)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}