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
    private let countdownNode = CountdownNode()
    private var hasGameStarted = false
    
    private let pauseButtonNode = PauseButtonNode()
    private var isGamePaused = false
    
    let scoreNode = SKLabelNode(text: "0")
    
    private var jumpRecognizer: UISwipeGestureRecognizer!
    private var duckRecognizer: UISwipeGestureRecognizer!
    
    private let tileSize = (width: 32, height: 32)
    
    private let grid = SKSpriteNode()
    private var logicEngine: LogicEngine!
    private var myPlayer: SKSpriteNode!
    private var myPlayerNumber: Int!
    
    var gameState: GameState!
    var players = [Int: SKSpriteNode]()
    var obstacles = [Int: SKSpriteNode]()

    private var gameSetupData: GameSetupData!

    private var isMultiplayer: Bool {
        return gameSetupData.mode == GameMode.Multiplayer || gameSetupData.mode == GameMode.SpecialMultiplayer
    }

    func setUpWith(data: GameSetupData) {
        gameSetupData = data
    }

    var initialGhostStore: GhostStore?

    // MARK: Overridden methods
    
    override func didMoveToView(view: SKView) {
        initLogicEngine()
        gameState = logicEngine.state
        gameState.observer = self
        myPlayerNumber = gameState.myPlayer.playerNumber
        // Assign the delegate to the logic engine to begin receiving updates
        GameNetworkPortal._instance.gameStateDelegate = logicEngine

        initObstacles()
        initPlayers()
        initGrid()
        initCountdownTimer()
        initPauseButton()
        initScore()
        
        // Set game to 30FPS
        view.frameInterval = 2
        setupGestureRecognizers(view)
        GameNetworkPortal._instance.send(.GameReady)
    }

    override func update(currentTime: CFTimeInterval) {
        guard logicEngine != nil && gameState != nil && !isGamePaused else {
            return
        }
        if gameState.allPlayersReady && !hasGameStarted{
            countdownNode.updateCountdownTime(currentTime)
        } else if hasGameStarted {
            logicEngine.update()
        }
    }

    // MARK: Initialisers
    
    private func initLogicEngine() {
        if initialGhostStore == nil {
            logicEngine = LogicEngine(mode: gameSetupData.mode, peers: gameSetupData.peers, seed: gameSetupData.seed, host: gameSetupData.host)
        } else {
            logicEngine = LogicEngine(ghostStore: initialGhostStore!)
        }
    }

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
        countdownNode.delegate = self
        countdownNode.position = CGPoint(x: size.width / 2, y: 0)
        countdownNode.zPosition = 995
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

    private func initScore() {
        scoreNode.horizontalAlignmentMode = .Right
        scoreNode.fontName = "HelveticaNeue-Medium"
        scoreNode.zPosition = 990
        scoreNode.position = CGPoint(x: size.width - 20,
                                     y: size.height / 2 - scoreNode.frame.height * 2)
        grid.addChild(scoreNode)
    }
    
    // MARK: Rendering

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
    
    func createObstacleNode(obstacle: Obstacle) -> SKSpriteNode {
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
    func calculateRenderPositionFor(object: GameObject) -> CGPoint {
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
    
    func addGestureRecognizers() {
        view!.addGestureRecognizer(jumpRecognizer)
        view!.addGestureRecognizer(duckRecognizer)
    }
    
    func removeGestureRecognizers() {
        view!.removeGestureRecognizer(jumpRecognizer)
        view!.removeGestureRecognizer(duckRecognizer)
    }
    
    func handleUpSwipe(sender: UISwipeGestureRecognizer) {
        guard hasGameStarted else {
            return
        }
        let event: GameEvent = gameSetupData.isHost ? .FloatingObstacleGenerated : .PlayerDidJump
        logicEngine.handleEvent(event, playerNumber: myPlayerNumber)
    }

    func handleDownSwipe(sender: UISwipeGestureRecognizer) {
        guard hasGameStarted else {
            return
        }
        let event: GameEvent = gameSetupData.isHost ? .NonFloatingObstacleGenerated : .PlayerDidDuck
        logicEngine.handleEvent(event, playerNumber: myPlayerNumber)
    }
}

// MARK: CountdownDelegate
extension GameScene: CountdownDelegate {
    func didCountdownEnd() {
        hasGameStarted = true
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
        hasGameStarted = false
        countdownNode.reset()
        if countdownNode.parent == nil {
            grid.addChild(countdownNode)
        }
    }
    
    func leaveGameSelected() {
        NSNotificationCenter.defaultCenter().postNotificationName("exitGame", object: nil)
    }
}