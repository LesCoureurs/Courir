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
        let size = CGSize(width: texture.size().width, height: texture.size().height)
        super.init(texture: texture, color: UIColor.clearColor(), size: size)
        
        position = IsoViewConverter.calculateRenderPositionFor(environment)
        anchorPoint = CGPointMake(0, 0)
        zPosition = -99
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}