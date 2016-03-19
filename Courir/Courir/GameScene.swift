//
//  GameScene.swift
//  Courir
//
//  Created by Karen Ang on 19/3/16.
//  Copyright (c) 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    var player: SKNode!
    var background: SKSpriteNode!

    var maxBackgroundOffset: CGFloat!
    var backgroundResetX: CGFloat!

    override func didMoveToView(view: SKView) {
        backgroundColor = UIColor.whiteColor()
        setupBackground(imageNamed: backgroundImageName)
        player = createPlayer()

        background.zPosition = 0
        addChild(player)
        addChild(background)
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        
        let swipeUpRecognizer = UISwipeGestureRecognizer(target: self,
            action: Selector("handleUpSwipe:"))
        swipeUpRecognizer.direction = .Up
        view.addGestureRecognizer(swipeUpRecognizer)
        
        let swipeDownRecognizer = UISwipeGestureRecognizer(target: self,
            action: Selector("handleDownSwipe:"))
        swipeDownRecognizer.direction = .Down
        view.addGestureRecognizer(swipeDownRecognizer)
    }
    
    func handleUpSwipe(sender: UISwipeGestureRecognizer) {
        jumpPlayer(0.6, height: 300)
    }
    
    func jumpPlayer(duration: NSTimeInterval, height: CGFloat) {
        // using the formula x = x0 + vt + 0.5*at^2
        let originalY = player.position.y
        let maxHeight = -height
        
        // acceleration to reach max height in duration a = 4x/t^2
        let acceleration = 4 * maxHeight / (CGFloat(duration) * CGFloat(duration))
        // initial velocity to reach max height in duration v = -at/2
        let velocity = -CGFloat(duration) * acceleration / 2
        
        let jumpUpAction = SKAction.customActionWithDuration(duration) {
            (node, time) in
            let y = originalY + velocity * time + 0.5 * acceleration * time * time
            let newPosition = CGPoint(x: node.position.x, y: y)
            node.position = newPosition
        }
        
        player.runAction(jumpUpAction)
    }
    
    func handleDownSwipe(sender: UISwipeGestureRecognizer) {
        
    }
    
    private func createPlayer() -> SKNode {
        let player = SKShapeNode(circleOfRadius: 30)
        
        player.fillColor = UIColor.blackColor()
        player.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame) - playerOffset)
        
        player.zPosition = 1
        return player
    }

    private func setupBackground(imageNamed name: String) {
        let bgNode = SKSpriteNode(imageNamed: name)
        bgNode.anchorPoint = CGPoint(x: 0, y: 0.5)
        bgNode.position = CGPoint(x: 0, y: CGRectGetMidY(frame))

        backgroundResetX = bgNode.position.x
        maxBackgroundOffset = -frame.size.width

        background = bgNode
    }

    override func update(currentTime: CFTimeInterval) {
        if background.position.x <= maxBackgroundOffset {
            background.position.x = backgroundResetX
        }

        background.position.x -= backgroundSpeed
    }
}
