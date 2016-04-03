//
//  GameScene.swift
//  Courir
//
//  Created by Karen Ang on 19/3/16.
//  Copyright (c) 2016 NUS CS3217. All rights reserved.
//

import SpriteKit
import MultipeerConnectivity

class GameScene: SKScene {

    // MARK: Properties
    private let countdownNode = SKLabelNode(text: "\(countdownTimerStart)")
    private var hasGameStarted = false
    private var coundownStartTimeInterval: CFTimeInterval?
    
    private let pauseButtonNode = PauseButtonNode()
    private var isGamePaused = false
    
    private let tileSize = (width: 32, height: 32)
    
    private let grid = SKSpriteNode()
    private var logicEngine: LogicEngine!
    
    private var gameState: GameState!
    private var myPlayer: SKSpriteNode!
    private var myPlayerNumber: Int!
    private var players = [Int: SKSpriteNode]()
    private var obstacles = [Int: SKSpriteNode]()
    
    private var jumpRecognizer: UISwipeGestureRecognizer!
    private var duckRecognizer: UISwipeGestureRecognizer!

    var seed: String?
    var isMultiplayer = false
    var peers = [MCPeerID]()

    // MARK: Overridden methods
    
    override func didMoveToView(view: SKView) {
        logicEngine = LogicEngine(seed: seed, isMultiplayer: isMultiplayer, peers: peers)
        logicEngine.delegate = self
        gameState = logicEngine.state
        myPlayerNumber = gameState.myPlayer.playerNumber
        // Assign the delegate to the logic engine to begin receiving updates
        GameNetworkPortal._instance.gameStateDelegate = logicEngine

        initObstacles()
        initPlayers()
        initGrid()
        initCountdownTimer()
        initPauseButton()

        setupGestureRecognizers(view)
        GameNetworkPortal._instance.send(.GameReady)
    }

    override func update(currentTime: CFTimeInterval) {
        guard logicEngine != nil && gameState != nil && !isGamePaused else {
            return
        }
        if gameState.allPlayersReady && !hasGameStarted{
            if let start = coundownStartTimeInterval {
                let timeSinceStart = Int(currentTime - start)
                let countdownValue = countdownTimerStart - timeSinceStart
                if countdownValue > 0 {
                    countdownNode.text = "\(countdownValue)"
                } else {
                    countdownNode.removeFromParent()
                    hasGameStarted = true
                }
            } else {
                coundownStartTimeInterval = currentTime
            }
        } else if hasGameStarted {
            logicEngine.update()
        }
    }

    // MARK: Initialisers

    private func initObstacles() {
        for obstacle in gameState.obstacles {
            obstacle.observer = self
            obstacles[obstacle.identifier] = createObstacleNode(obstacle)
        }
    }
    
    private func initPlayers() {
        for player in gameState.players {
            player.observer = self
            let node = createPlayerNode(player)
            players[player.playerNumber] = node
        }
    }
    
    private func initGrid() {
        grid.position = CGPoint(x: 0, y: size.height/2)
        addChild(grid)
        renderIsoGrid()
    }
    
    private func initCountdownTimer() {
        countdownNode.fontName = "HelveticaNeue-Bold"
        countdownNode.position = CGPoint(x: size.width / 2, y: 0)
        countdownNode.fontSize *= 3
        countdownNode.zPosition = 995
        countdownNode.fontColor = UIColor.blackColor()
        grid.addChild(countdownNode)
    }
    
    private func initPauseButton() {
        guard !isMultiplayer else {
            return
        }
        pauseButtonNode.delegate = self
        pauseButtonNode.zPosition = 990
        pauseButtonNode.position = CGPoint(x: pauseButtonNode.frame.width / 2 + 20,
                                           y: (-size.height / 2 + pauseButtonNode.frame.height))
        grid.addChild(pauseButtonNode)
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
    
    /// Convert point to respective screen coordinate in an isometric projection
    private func pointToIso(p: CGPoint) -> CGPoint {
        return CGPointMake(p.x + p.y, (p.y - p.x) / 2)
    }

    private func createGameObjectNode(object: GameObject, imageName: String) -> SKSpriteNode {
        let sprite = SKSpriteNode(imageNamed: imageName)
        sprite.position = calculateRenderPositionFor(object)
        sprite.anchorPoint = CGPointMake(0, 0)
        grid.addChild(sprite)
        return sprite
    }
    
    private func createPlayerNode(player: Player) -> SKSpriteNode {
        let playerSprite = createGameObjectNode(player, imageName: "iso_player")
        playerSprite.zPosition = 2
        return playerSprite
    }
    
    private func createObstacleNode(obstacle: Obstacle) -> SKSpriteNode {
        let obstacleSprite: SKSpriteNode
        switch obstacle.type {
            case .NonFloating:
                obstacleSprite = createGameObjectNode(obstacle, imageName: "iso_non_floating_obstacle")
                obstacleSprite.zPosition = 1
            case .Floating:
                obstacleSprite = createGameObjectNode(obstacle, imageName: "iso_floating_obstacle")
                obstacleSprite.zPosition = 3
        }
        
        return obstacleSprite
    }
    
    /// Convert world coordinates of object to screen coordinates
    private func calculateRenderPositionFor(object: GameObject) -> CGPoint {
        // multiple is to convert object's coordinates to coordinates in the actual larger grid
        let multiple = Double(tileSize.width / unitsPerGameGridCell) / 2
        let x = CGFloat(Double(object.xCoordinate) * multiple)
        let y = CGFloat(Double(object.yCoordinate) * multiple)
        
        var isoPoint = pointToIso(CGPointMake(x, y))
        // offset as a result of having objects that take up multiple tiles
        isoPoint.y -= (CGFloat(object.xWidth)/CGFloat(tileSize.height) - 1) * 8
        return isoPoint
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
        guard hasGameStarted else {
            return
        }
        logicEngine.handleEvent(.PlayerDidJump, playerNumber: myPlayerNumber)
    }

    func handleDownSwipe(sender: UISwipeGestureRecognizer) {
        guard hasGameStarted else {
            return
        }
        logicEngine.handleEvent(.PlayerDidDuck, playerNumber: myPlayerNumber)
    }
    
    // MARK: Pause Menu methods
    private func showPauseMenu() {
        
    }
}

// MARK: LogicEngineDelegate
extension GameScene: LogicEngineDelegate {
    func didGenerateObstacle(obstacle: Obstacle) {
        obstacle.observer = self
        obstacles[obstacle.identifier] = createObstacleNode(obstacle)
    }
    
    func didRemoveObstacle(obstacle: Obstacle) {
        obstacles[obstacle.identifier]?.removeFromParent()
    }

    func playerDidFinish(playerNumber: Int, score: Int) {
        print("Player \(playerNumber) finished with score = \(score)")
    }
    
    func gameDidEnd() {
        let gameOverData = ["eventRawValue": GameEvent.GameDidEnd.rawValue, "gameResult": gameState.scoreTracking]
        
        NSNotificationCenter.defaultCenter().postNotificationName("showEndGameMenu", object: self, userInfo: gameOverData as [NSObject : AnyObject])
        print("Game did end. Score tracking: \(gameState.scoreTracking)")
    }
}


// MARK: Observer
extension GameScene: Observer {
    func didChangeProperty(propertyName: String, from: AnyObject?) {
        if let object = from as? Player {
            handleUpdatePlayerNode(object, propertyName: propertyName)
        } else if let object = from as? Obstacle {
            handleUpdateObstacleNode(object, propertyName: propertyName)
        }
    }
    
    /// Handle the updating of the player node whose property has changed
    private func handleUpdatePlayerNode(player: Player, propertyName: String) {
        guard let node = players[player.playerNumber] else {
            return
        }
        
        switch propertyName {
            case "xCoordinate", "yCoordinate":
                updatePositionFor(player, withNode: node)
            case "zCoordinate":
                updateJumpingPositionFor(player, withNode: node)
            case "state":
                updatePlayerTexture(player, withNode: node)
            default:
                return
        }
    }
    
    /// Update screen coordinates for object whose x and/or y coordinate has changed
    private func updatePositionFor(object: GameObject, withNode node: SKSpriteNode) {
        node.position = calculateRenderPositionFor(object)
    }
    
    /// Update screen y coordinate for the jumping player
    private func updateJumpingPositionFor(player: Player, withNode node: SKSpriteNode) {
        node.position.y = calculateRenderPositionFor(player).y + CGFloat(player.zCoordinate)
    }
    
    /// Update the player's texture based on state
    private func updatePlayerTexture(player: Player, withNode node: SKSpriteNode) {
        switch player.physicalState {
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
    
    /// Handle the updating of the obstacle node whose property has changed
    private func handleUpdateObstacleNode(obstacle: Obstacle, propertyName: String) {
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

// MARK: PauseButtonDelegate
extension GameScene: PauseButtonDelegate {
    func pauseButtonTouched() {
        isGamePaused = true
        let pauseMenu = PauseMenuNode()
        pauseMenu.position = CGPoint(x: size.width / 2, y: 0)
        pauseMenu.delegate = self
        pauseMenu.userInteractionEnabled = true
        grid.addChild(pauseMenu)
    }
}

// MARK: PauseMenuDelegate
extension GameScene: PauseMenuDelegate {
    func pauseMenuDismissed() {
        isGamePaused = false
        coundownStartTimeInterval = nil
        hasGameStarted = false
        countdownNode.text = "\(countdownTimerStart)"
        if countdownNode.parent == nil {
            grid.addChild(countdownNode)
        }
    }
    
    func leaveGameSelected() {
        NSNotificationCenter.defaultCenter().postNotificationName("exitGame", object: nil)
    }
}