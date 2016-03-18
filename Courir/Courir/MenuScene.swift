//
//  MenuScene.swift
//  Courir
//
//  Created by Karen Ang on 19/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

class MenuScene: SKScene {
    var playButton: SKLabelNode!

    override func didMoveToView(view: SKView) {
        playButton = SKLabelNode()
        playButton.text = "Play"
        playButton.fontSize = 45
        playButton.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
        addChild(playButton)
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)

            if nodeAtPoint(location) == playButton {
                let gameScene = GameScene(size: size)
                let skView = view as SKView!
                skView.ignoresSiblingOrder = true
                gameScene.scaleMode = .AspectFill
                skView.presentScene(gameScene)
            }
        }
    }

    override func update(currentTime: NSTimeInterval) {
        
    }
}

