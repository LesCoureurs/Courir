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
    private var myPlayerNumber: Int!
    
    var gameState: GameState!
    var players = [Int: PlayerSpriteNode]()
    var obstacles = [Int: SKSpriteNode]()
    var environmentNodes = [Int: EnvironmentSpriteNode]()

    var initialGhostStore: GhostStore?
    var seed: NSData?
    var isMultiplayer = false
    var peers = [MCPeerID]()
    
    // MARK: Overridden methods
    
    override func didMoveToView(view: SKView) {
        initLogicEngine()
        gameState = logicEngine.state
        gameState.observer = self
        myPlayerNumber = gameState.myPlayer.playerNumber
        // Assign the delegate to the logic engine to begin receiving updates
        GameNetworkPortal._instance.gameStateDelegate = logicEngine

        initEnvironment()
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
            updatePlayerTextures()
        }
    }

    private func updatePlayerTextures() {
        for (_, player) in players {
            player.showNextAnimationFrame()
        }
    }
    // MARK: Initialisers
    
    private func initLogicEngine() {
        if initialGhostStore == nil {
            logicEngine = LogicEngine(isMultiplayer: isMultiplayer, peers: peers, seed: seed)
        } else {
            logicEngine = LogicEngine(ghostStore: initialGhostStore!)
        }
    }
    
    private func initEnvironment() {
        for environmentObject in gameState.environmentObjects {
            environmentObject.observer = self
            environmentNodes[environmentObject.identifier] = createEnvironmentNode(environmentObject)
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

    private func createEnvironmentNode(environment: Environment) -> EnvironmentSpriteNode {
        let environmentSpriteNode = EnvironmentSpriteNode(environment: environment)
        grid.addChild(environmentSpriteNode)
        return environmentSpriteNode
    }
    
    private func createPlayerNode(player: Player) -> PlayerSpriteNode {
        let playerSprite = PlayerSpriteNode(player: player)
        grid.addChild(playerSprite)
        return playerSprite
    }
    
    func createObstacleNode(obstacle: Obstacle) -> SKSpriteNode {
        let obstacleSprite = ObstacleSpriteNode(obstacle: obstacle)
        grid.addChild(obstacleSprite)
        return obstacleSprite
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
        logicEngine.handleEvent(.PlayerDidJump, playerNumber: myPlayerNumber)
    }

    func handleDownSwipe(sender: UISwipeGestureRecognizer) {
        guard hasGameStarted else {
            return
        }
        logicEngine.handleEvent(.PlayerDidDuck, playerNumber: myPlayerNumber)
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