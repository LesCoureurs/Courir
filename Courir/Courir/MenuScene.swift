//
//  MenuScene.swift
//  Courir
//
//  Created by Karen Ang on 19/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

class MenuScene: SKScene {
    private let menuOptions = ["Play", "Multiplayer"]
    private var menuButtons = [SKLabelNode]()

    override func didMoveToView(view: SKView) {

        let defaultButtonPosition = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame) + CGFloat(menuButtonOffset / 2))
        for i in 0..<menuOptions.count {
            let position = CGPoint(x: defaultButtonPosition.x, y: defaultButtonPosition.y - CGFloat(i * menuButtonOffset))
            let button = createMenuButton(withLabel: menuOptions[i], atPosition: position)
            menuButtons.append(button)
        }
    }

    private func createMenuButton(withLabel label: String, atPosition position: CGPoint) -> SKLabelNode {
        let button = SKLabelNode()
        button.text = label
        button.fontSize = menuButtonFontSize
        button.position = position
        addChild(button)
        return button
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            let node = nodeAtPoint(location)
            switch node {
            case menuButtons[0]:
                let gameScene = GameScene(size: size)
                let skView = view as SKView!
                skView.ignoresSiblingOrder = true
                gameScene.scaleMode = .AspectFill
                skView.presentScene(gameScene)
            case menuButtons[1]:
                break // Display Multiplayer Room Selection Scene
            default:
                break
            }
        }
    }

    override func update(currentTime: NSTimeInterval) {
        
    }
}

