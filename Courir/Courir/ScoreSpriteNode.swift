//
//  ScoreSpriteNode.swift
//  Courir
//
//  Created by Sebastian Quek on 8/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

class ScoreSpriteNode: SKSpriteNode {
    
    // ==============================================
    // Static variables and methods
    // ==============================================
    
    static private var hasInitTextures = false
    static private var digits = [SKTexture]()
    
    static private let size = CGSize(width: 72, height: 72)
    static private let yCoordinate = -10 * unitsPerGameGridCell
    static private let minXCoordinate = 18 * unitsPerGameGridCell
    static private let xCoordinateIncrement = 2 * unitsPerGameGridCell
    
    static private func initTextures() {
        for i in 0..<digitsAtlas.textureNames.count {
            digits.append(digitsAtlas.textureNamed("\(i)"))
        }
        hasInitTextures = true
    }
    
    static private func generatePositionForNthDigit(n: Int) -> CGPoint {
        let x = ScoreSpriteNode.minXCoordinate + n * ScoreSpriteNode.xCoordinateIncrement
        let y = ScoreSpriteNode.yCoordinate
        return IsoViewConverter.calculateRenderPositionFor(x, y)
    }
    
    // ==============================================
    // Instance variables and methods
    // ==============================================
    
    init() {
        if !ScoreSpriteNode.hasInitTextures {
            ScoreSpriteNode.initTextures()
        }
        
        let texture = ScoreSpriteNode.digits.first!
        super.init(texture: nil,
                   color: UIColor.clearColor(),
                   size: texture.size())
        
        position = IsoViewConverter.calculateRenderPositionFor(0, 0)
        anchorPoint = CGPointMake(0, 0)
        zPosition = 0
    }
    
    func setScore(score: Int) {
        dispatch_async(dispatch_get_main_queue()) {
            self.removeAllChildren()
            for (i, digit) in score.digits.enumerate() {
                let node = SKSpriteNode(texture: ScoreSpriteNode.digits[digit])
                node.anchorPoint = CGPointMake(0, 0)
                node.position = ScoreSpriteNode.generatePositionForNthDigit(i)
                node.size = ScoreSpriteNode.size
                self.addChild(node)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Int {
    var digits: [Int] {
        return description.characters.map {Int(String($0)) ?? 0}
    }
}