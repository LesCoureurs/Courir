//
//  GameScene.swift
//  Courir
//
//  Created by Karen Ang on 19/3/16.
//  Copyright (c) 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, LogicEngineDelegate {
    private let tileSize = (width: 32, height: 32)
    
    private let grid = SKSpriteNode()
    private let logicEngine = LogicEngine(playerNumber: 0)
    
    private var gameState: GameState!
    private var myPlayer: SKNode!
    private var obstacles = [String: SKNode]()

    override func didMoveToView(view: SKView) {
        logicEngine.setDelegate(self)
        gameState = logicEngine.state

        
        initObstacles()
        initPlayers()
        initGrid()
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
        setupGestureRecognizers(view)
    }
    
    private func initGrid() {
        grid.position = CGPoint(x: 0, y: size.height/2)
        addChild(grid)
        renderIsoGrid()
    }
    
    private func initObstacles() {
        let obstacleNodes = gameState.obstacles.map { createObstacle($0) }
        for node in obstacleNodes {
            obstacles[node.name!] = node
        }
    }
    
    private func initPlayers() {
        myPlayer = createPlayer(gameState.myPlayer)
        for i in 1...3 { // Replace when game state contains data of other players
            createPlayer(Player(playerNumber: i))
        }
    }
    
    private func renderIsoGrid() {
        let numCols = 32
        let numRows = 32
        
        for i in 0..<numRows {
            for j in 0..<numCols {
                let point = pointToIso(CGPoint(x: (j * tileSize.width / 2),
                                               y: (i * tileSize.height / 2)))
                placeTile(imageNamed: "iso_grid_tile", withPosition: point)
            }
        }
    }
    
    private func pointToIso(p: CGPoint) -> CGPoint {
        return CGPointMake(p.x + p.y, (p.y - p.x) / 2)
    }
    
    private func placeTile(imageNamed image: String, withPosition: CGPoint) {
        let tileSprite = SKSpriteNode(imageNamed: image)
        
        tileSprite.position = withPosition
        tileSprite.anchorPoint = CGPoint(x: 0, y: 0)
        tileSprite.size = CGSize(width: 32, height: 16)
        
        grid.addChild(tileSprite)
    }

    private func calculateRenderPositionFor(object: GameObject) -> CGPoint {
        // multiple is to convert object's coordinates to coordinates in the actual grid
        let multiple = Double(tileSize.width / unitsPerGameGridCell) / 2
        let x = CGFloat(Double(object.xCoordinate) * multiple)
        let y = CGFloat(Double(object.yCoordinate) * multiple)
        return pointToIso(CGPointMake(x, y))
    }

    private func createGameObject(object: GameObject, imageName: String) -> SKSpriteNode {
        let sprite = SKSpriteNode(imageNamed: imageName)
        sprite.position = calculateRenderPositionFor(object)
        sprite.anchorPoint = CGPointMake(0, 0)
        grid.addChild(sprite)
        return sprite
    }
    
    private func createPlayer(player: Player) -> SKNode {
        let playerSprite = createGameObject(player, imageName: "iso_player")
        playerSprite.zPosition = 2
        playerSprite.position.y -= CGFloat(playerSprite.size.height/CGFloat(tileSize.height) - 1) * 8
        return playerSprite
    }
    
    private func createObstacle(obstacle: Obstacle) -> SKNode {
        let obstacleSprite = createGameObject(obstacle, imageName: "iso_non_floating_obstacle")
        obstacleSprite.zPosition = 1
        obstacleSprite.name = obstacle.identifier
        return obstacleSprite
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

    private func setupGestureRecognizers(view: SKView) {
        let swipeUpRecognizer = UISwipeGestureRecognizer(target: self,
            action: #selector(GameScene.handleUpSwipe(_:)))
        swipeUpRecognizer.direction = .Up
        view.addGestureRecognizer(swipeUpRecognizer)
        
        let swipeDownRecognizer = UISwipeGestureRecognizer(target: self,
            action: #selector(GameScene.handleDownSwipe(_:)))
        swipeDownRecognizer.direction = .Down
        view.addGestureRecognizer(swipeDownRecognizer)
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
