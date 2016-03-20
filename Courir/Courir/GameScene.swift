//
//  GameScene.swift
//  Courir
//
//  Created by Karen Ang on 19/3/16.
//  Copyright (c) 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    let grid = SKSpriteNode()
    let tileSize = (width: 32, height: 32)
    
    var player: SKNode!

    override func didMoveToView(view: SKView) {
        player = createPlayer()
        addChild(player)

        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        
        grid.position = CGPoint(x: 0, y: 0)
        addChild(grid)
        
        setupGestureRecognizers(view)
        render2DGrid()
    }
    
    private func setupGestureRecognizers(view: SKView) {
        let swipeUpRecognizer = UISwipeGestureRecognizer(target: self,
            action: Selector("handleUpSwipe:"))
        swipeUpRecognizer.direction = .Up
        view.addGestureRecognizer(swipeUpRecognizer)
        
        let swipeDownRecognizer = UISwipeGestureRecognizer(target: self,
            action: Selector("handleDownSwipe:"))
        swipeDownRecognizer.direction = .Down
        view.addGestureRecognizer(swipeDownRecognizer)
    }
    
    private func place2DTile(imageNamed image: String, withPosition: CGPoint) {
        let tileSprite = SKSpriteNode(imageNamed: image)
        
        tileSprite.position = withPosition
        tileSprite.anchorPoint = CGPoint(x: 0, y: 0)
        
        grid.addChild(tileSprite)
    }
    
    private func render2DGrid() {
        for i in 0..<24 {
            for j in 0..<32 {
                let point = CGPoint(x: (j*tileSize.width), y: -(i*tileSize.height))
                place2DTile(imageNamed: "grid_tile", withPosition: point)
            }
        }
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

    override func update(currentTime: CFTimeInterval) {

    }
}
