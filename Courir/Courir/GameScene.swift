//
//  GameScene.swift
//  Courir
//
//  Created by Karen Ang on 19/3/16.
//  Copyright (c) 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, LogicEngineDelegate, Observer {
    private let tileSize = (width: 32, height: 32)
    
    private let grid = SKSpriteNode()
    private let logicEngine = LogicEngine(playerNumber: 0)
    
    private var gameState: GameState!
    private var myPlayer: SKSpriteNode!
    private var players = [Int: SKSpriteNode]()
    private var obstacles = [Int: SKSpriteNode]()
    
    private var jumpRecognizer: UISwipeGestureRecognizer!
    private var duckRecognizer: UISwipeGestureRecognizer!

    
    // MARK: Initialisers
    
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
        for obstacle in gameState.obstacles {
            obstacle.observer = self
            obstacles[obstacle.identifier] = createObstacle(obstacle)
        }
    }
    
    private func initPlayers() {
        gameState.myPlayer.run()
        gameState.myPlayer.observer = self
        myPlayer = createPlayer(gameState.myPlayer)
        players[gameState.myPlayer.playerNumber] = myPlayer
        for i in 1...3 { // Replace when game state contains data of other players
            players[i] = createPlayer(Player(playerNumber: i))
        }
    }
    
    private func renderIsoGrid() {
        func createGridTileAt(withPosition: CGPoint) {
            let tileSprite = SKSpriteNode(imageNamed: "iso_grid_tile")
            
            tileSprite.position = withPosition
            tileSprite.anchorPoint = CGPoint(x: 0, y: 0)
            tileSprite.size = CGSize(width: 32, height: 16)
            
            grid.addChild(tileSprite)
        }
        
        for i in 0..<gameGridSize {
            for j in 0..<gameGridSize {
                let point = pointToIso(CGPoint(x: (j * tileSize.width / 2),
                                               y: (i * tileSize.height / 2)))
                createGridTileAt(point)
            }
        }
    }
    
    private func pointToIso(p: CGPoint) -> CGPoint {
        return CGPointMake(p.x + p.y, (p.y - p.x) / 2)
    }

    private func createGameObject(object: GameObject, imageName: String) -> SKSpriteNode {
        let sprite = SKSpriteNode(imageNamed: imageName)
        sprite.position = calculateRenderPositionFor(object)
        sprite.anchorPoint = CGPointMake(0, 0)
        grid.addChild(sprite)
        return sprite
    }
    
    private func createPlayer(player: Player) -> SKSpriteNode {
        let playerSprite = createGameObject(player, imageName: "iso_player")
        playerSprite.zPosition = 2
        return playerSprite
    }
    
    private func createObstacle(obstacle: Obstacle) -> SKSpriteNode {
        let obstacleSprite: SKSpriteNode
        switch obstacle.type {
            case .NonFloating:
                obstacleSprite = createGameObject(obstacle, imageName: "iso_non_floating_obstacle")
                obstacleSprite.zPosition = 1
            case .Floating:
                obstacleSprite = createGameObject(obstacle, imageName: "iso_floating_obstacle")
                obstacleSprite.zPosition = 3
        }
        
        return obstacleSprite
    }
    
    private func calculateRenderPositionFor(object: GameObject) -> CGPoint {
        // multiple is to convert object's coordinates to coordinates in the actual grid
        let multiple = Double(tileSize.width / unitsPerGameGridCell) / 2
        let x = CGFloat(Double(object.xCoordinate) * multiple)
        let y = CGFloat(Double(object.yCoordinate) * multiple)
        
        var isoPoint = pointToIso(CGPointMake(x, y))
        // offset as a result of having objects that take up multiple tiles
        isoPoint.y -= (CGFloat(object.xWidth)/CGFloat(tileSize.height) - 1) * 8
        return isoPoint
    }

    
    // MARK: Update methods

    override func update(currentTime: CFTimeInterval) {
        logicEngine.update()
    }
    
    private func updatePositionFor(object: GameObject, withNode node: SKSpriteNode) {
        node.position = calculateRenderPositionFor(object)
    }
    
    
    // MARK: Gesture handling methods

    private func setupGestureRecognizers(view: SKView) {
        jumpRecognizer = UISwipeGestureRecognizer(target: self,
            action: #selector(GameScene.handleUpSwipe(_:)))
        jumpRecognizer.direction = .Up
        
        duckRecognizer = UISwipeGestureRecognizer(target: self,
            action: #selector(GameScene.handleDownSwipe(_:)))
        duckRecognizer.direction = .Down
        
        addGestureRecognizers()
    }
    
    private func addGestureRecognizers() {
        view!.addGestureRecognizer(jumpRecognizer)
        view!.addGestureRecognizer(duckRecognizer)
    }
    
    private func removeGestureRecognizers() {
        view!.removeGestureRecognizer(jumpRecognizer)
        view!.removeGestureRecognizer(duckRecognizer)
    }
    
    func handleUpSwipe(sender: UISwipeGestureRecognizer) {
        jumpPlayer(jumpDuration, height: CGFloat(3 * unitsPerGameGridCell), player: myPlayer, completion: addGestureRecognizers)
    }
    
    private func jumpPlayer(duration: NSTimeInterval, height: CGFloat, player: SKNode, completion: ()->()) {
        logicEngine.handleEvent(.PlayerDidJump, player: 0)
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

        let jumpTextureChange = SKAction.setTexture(playerJumpTexture)

        player.runAction(jumpTextureChange)
        player.runAction(jumpUpAction, completion: {
            player.runAction(resetPlayerTexture)
            completion()
        })
    }

    func handleDownSwipe(sender: UISwipeGestureRecognizer) {
        logicEngine.handleEvent(.PlayerDidDuck, player: 0)
    }
    

    // MARK: LogicEngineDelegate
    
    func didGenerateObstacle(obstacle: Obstacle) {
        obstacle.observer = self
        obstacles[obstacle.identifier] = createObstacle(obstacle)
    }
    
    func didRemoveObstacle(obstacle: Obstacle) {
        obstacles[obstacle.identifier]?.removeFromParent()
    }

    func gameDidEnd(score: Int) {
        let gameOverData = ["eventRawValue": GameEvent.GameDidEnd.rawValue, "score": score]
        NSNotificationCenter.defaultCenter().postNotificationName("showAlert", object: self, userInfo: gameOverData)
    }
    
    
    // MARK: Observer
    
    func didChangeProperty(propertyName: String, from: AnyObject?) {
        if let object = from as? Player {
            updatePlayerNode(object, propertyName: propertyName)
        } else if let object = from as? Obstacle {
            updateObstacleNode(object, propertyName: propertyName)
        }
    }
    
    private func updatePlayerNode(player: Player, propertyName: String) {
        guard let node = players[player.playerNumber] else {
            return
        }
        
        switch propertyName {
            case "xCoordinate", "yCoordinate":
                updatePositionFor(player, withNode: node)
            case "state":
                updatePlayerState(player, withNode: node)
            default:
                return
        }
    }
    
    private func updatePlayerState(player: Player, withNode node: SKSpriteNode) {
        print("\(player.playerNumber)'s new state: \(player.state)")
        switch player.state {
            case .Ducking(_):
                removeGestureRecognizers()
                node.texture = playerDuckTexture
            case .Jumping(_):
                removeGestureRecognizers()
                node.texture = playerJumpTexture
            case .Running, .Stationary, .Invulnerable(_):
                addGestureRecognizers()
                node.texture = playerTexture
        }
    }
    
    private func updateObstacleNode(obstacle: Obstacle, propertyName: String) {
        guard let node = obstacles[obstacle.identifier] else {
            return
        }
        
        switch propertyName {
            case "xCoordinate", "yCoordinate":
                updatePositionFor(obstacle, withNode: node)
            default:
                return
        }
    }
}
