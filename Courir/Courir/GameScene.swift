//
//  GameScene.swift
//  Courir
//
//  Created by Karen Ang on 19/3/16.
//  Copyright (c) 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, LogicEngineDelegate {
    private let grid = SKSpriteNode()
    private let tileSize = (width: 32, height: 32)
    
    private let logicEngine = LogicEngine(playerNumber: 0)
    private var gameState: GameState!
    private var myPlayer: SKNode!
    private var obstacles = [String: SKNode]()

    override func didMoveToView(view: SKView) {
        logicEngine.setDelegate(self)
        gameState = logicEngine.state

        let obstacleNodes = gameState.obstacles.map { createObstacle($0) }
        for node in obstacleNodes {
            obstacles[node.name!] = node
        }

        myPlayer = createPlayer(gameState.myPlayer)

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
        let numCols = Int(size.width / CGFloat(tileSize.width))
        let numRows = Int(size.height / CGFloat(tileSize.height))
        for i in 0..<numRows {
            for j in 0..<numCols {
                let point = CGPoint(x: (j*tileSize.width), y: (i*tileSize.height))
                place2DTile(imageNamed: "grid_tile", withPosition: point)
            }
        }
    }
    
    func handleUpSwipe(sender: UISwipeGestureRecognizer) {
        jumpPlayer(0.6, height: 300, player: myPlayer)
    }
    
    func jumpPlayer(duration: NSTimeInterval, height: CGFloat, player: SKNode) {
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

    private func calculateRenderPositionFor(object: GameObject) -> CGPoint {
        let x = CGFloat(object.xCoordinate * tileSize.width + object.xWidth / 2 * tileSize.width)
        let y = CGFloat(object.yCoordinate * tileSize.width + object.yWidth / 2 * tileSize.height)
        return CGPoint(x: x, y: y)
    }

    private func createPlayer(player: Player) -> SKNode {
        let playerNode = SKShapeNode(rectOfSize: CGSize(width: player.xWidth*tileSize.width, height: player.yWidth*tileSize.height))
        
        playerNode.fillColor = SKColor.blackColor()
        playerNode.zPosition = 1
        playerNode.lineWidth = 0
        playerNode.position = calculateRenderPositionFor(player)

        addChild(playerNode)
        return playerNode
    }
    
    private func createObstacle(obstacle: Obstacle) -> SKNode {
        let obstacleNode = SKShapeNode(rectOfSize: CGSize(width: obstacle.xWidth*tileSize.width, height: obstacle.yWidth*tileSize.height))
        
        obstacleNode.fillColor = SKColor.grayColor()
        obstacleNode.zPosition = 1
        obstacleNode.lineWidth = 0
        obstacleNode.position = calculateRenderPositionFor(obstacle)

        obstacleNode.name = obstacle.identifier
        addChild(obstacleNode)
        return obstacleNode
    }

    private func updatePositionFor(object: GameObject, withNode node: SKNode) {
        node.position = calculateRenderPositionFor(object)
    }

    override func update(currentTime: CFTimeInterval) {
        logicEngine.update()
        for obstacle in gameState.obstacles {
            if let node = self.obstacles[obstacle.identifier] {
                updatePositionFor(obstacle, withNode: node)
            }
        }
    }

    func didGenerateObstacle(obstacle: Obstacle) {
        let obstacleNode = createObstacle(obstacle)
        obstacles[obstacleNode.name!] = (obstacleNode)
    }
    
    func didRemoveObstacle(obstacle: Obstacle) {
        obstacles[obstacle.identifier]?.removeFromParent()
    }

    func didCollide() {

    }

    func didJump() {

    }

    func didDuck() {

    }

    func gameDidEnd() {

    }
}
