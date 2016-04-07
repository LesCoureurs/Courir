//
//  ObstacleSpriteNode.swift
//  Courir
//
//  Created by Sebastian Quek on 6/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

class ObstacleSpriteNode: SKSpriteNode {
    
    init(obstacle: Obstacle) {
        var texture: SKTexture
        var zPosition: CGFloat = 0
        
        switch obstacle.type {
        case .Floating:
            texture = SKTexture(imageNamed: "obstacle-floating")
            zPosition = PlayerSpriteNode.firstZPosition + 1
        case .NonFloating:
            texture = SKTexture(imageNamed: "obstacle-non-floating")
            zPosition = 0
        }
        
        super.init(texture: texture, color: UIColor.clearColor(), size: texture.size())
        
        self.position = IsoViewConverter.calculateRenderPositionFor(obstacle)
        self.anchorPoint = CGPointMake(0, 0)
        self.zPosition = zPosition
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}