//
//  GameScene.swift
//  Courir
//
//  Created by Karen Ang on 19/3/16.
//  Copyright (c) 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    var player: SKShapeNode!
    var background: SKSpriteNode!

    var maxBackgroundOffset: CGFloat!
    var backgroundResetX: CGFloat!

    var currZPosition: CGFloat = 0

    override func didMoveToView(view: SKView) {
        backgroundColor = UIColor.whiteColor()
        setupBackground(imageNamed: backgroundImageName)

        player = SKShapeNode(circleOfRadius: 30)
        player.fillColor = UIColor.blackColor()
        player.position = CGPoint(x: CGRectGetMidX(frame), y: CGRectGetMidY(frame) - playerOffset)

        background.zPosition = currZPosition++
        player.zPosition = currZPosition++
        addChild(player)
        addChild(background)
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
