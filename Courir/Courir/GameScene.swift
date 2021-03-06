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

    // ==============================================
    // MARK: Properties
    // ==============================================

    private let countdownNode = CountdownNode()
    private(set) var hasGameStarted = false
    
    let pauseButtonNode = PauseButtonNode()
    private var isGamePaused = false
    
    let scoreNode = ScoreSpriteNode()
    
    private var jumpRecognizer: UISwipeGestureRecognizer!
    private var duckRecognizer: UISwipeGestureRecognizer!
    
    private let grid = SKSpriteNode()
    var logicEngine: LogicEngine!
    private var myPlayerNumber: Int!
    
    var gameState: GameState!
    var players = [Int: PlayerSpriteNode]()
    var obstacles = [Int: ObstacleSpriteNode]()
    var environmentNodes = [Int: EnvironmentSpriteNode]()

    private var gameSetupData: GameSetupData!

    private var isMultiplayer: Bool {
        return gameSetupData.mode == GameMode.Multiplayer || gameSetupData.mode == GameMode.SpecialMultiplayer
    }

    var initialGhostStore: GhostStore?
    
    // ==============================================
    // MARK: Overridden methods
    // ==============================================
    
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
        initResignActiveNotificationObserver()
        
        // Set game to 30FPS
        view.frameInterval = 1
        setupGestureRecognizers(view)
        gameSceneReady()
    }

    // ==============================================
    // MARK: Start & Setup
    // ==============================================

    func setUpWith(data: GameSetupData) {
        gameSetupData = data
    }

    func startGame() {
        countdownNode.start()
    }

    private func gameSceneReady() {
        if gameState.isMultiplayer {
            GameNetworkPortal._instance.send(.GameReady)
        } else {
            startGame()
        }
    }
    
    // ==============================================
    // MARK: Initialisers
    // ==============================================
    
    private func initLogicEngine() {
        if initialGhostStore == nil {
            logicEngine = LogicEngine(mode: gameSetupData.mode, peers: gameSetupData.peers, seed: gameSetupData.seed, host: gameSetupData.host)
        } else {
            logicEngine = LogicEngine(ghostStore: initialGhostStore!)
        }
    }
    
    private func initEnvironment() {
        for environment in gameState.environmentObjects {
            environmentNodes[environment.identifier] = createEnvironmentNode(environment)
        }
    }

    private func initObstacles() {
        for obstacle in gameState.obstacles {
            obstacles[obstacle.identifier] = createObstacleNode(obstacle)
        }
    }
    
    private func initPlayers() {
        for player in gameState.players {
            players[player.playerNumber] = createPlayerNode(player)
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
        pauseButtonNode.delegate = self
        pauseButtonNode.zPosition = 990
        pauseButtonNode.position = CGPoint(x: pauseButtonNode.frame.width / 2 + 20,
                                           y: (-size.height / 2 + pauseButtonNode.frame.height))
        grid.addChild(pauseButtonNode)
    }

    private func initScore() {
        grid.addChild(scoreNode)
    }

    private func initResignActiveNotificationObserver() {
        NSNotificationCenter.defaultCenter()
            .addObserver(self, selector: #selector(self.pauseButtonTouched),
                         name: UIApplicationWillResignActiveNotification, object: nil)
    }

    // ==============================================
    // MARK: Methods to create custom sprite nodes
    // ==============================================

    private func createEnvironmentNode(environment: Environment) -> EnvironmentSpriteNode {
        let environmentSpriteNode = EnvironmentSpriteNode(environment: environment)
        grid.addChild(environmentSpriteNode)
        return environmentSpriteNode
    }
    
    private func createPlayerNode(player: Player) -> PlayerSpriteNode {
        let playerSprite = PlayerSpriteNode(player: player, isMe: player === gameState.myPlayer)
        grid.addChild(playerSprite)
        return playerSprite
    }
    
    func createObstacleNode(obstacle: Obstacle) -> ObstacleSpriteNode {
        let obstacleSprite = ObstacleSpriteNode(obstacle: obstacle)
        grid.addChild(obstacleSprite)
        return obstacleSprite
    }
    
    
    // ==============================================
    // MARK: Gesture handling methods
    // ==============================================

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
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            var event: GameEvent = .PlayerDidJump
            if self.gameSetupData.isHost && self.gameSetupData.mode == .SpecialMultiplayer {
                event = .FloatingObstacleGenerated
            }
            self.logicEngine.handleEvent(event, playerNumber: self.myPlayerNumber)
        }
    }

    func handleDownSwipe(sender: UISwipeGestureRecognizer) {
        guard hasGameStarted else {
            return
        }
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            var event: GameEvent = .PlayerDidDuck
            if self.gameSetupData.isHost && self.gameSetupData.mode == .SpecialMultiplayer {
                event = .NonFloatingObstacleGenerated
            }
            self.logicEngine.handleEvent(event, playerNumber: self.myPlayerNumber)
        }
    }
}

// MARK: CountdownDelegate
extension GameScene: CountdownDelegate {
    func didCountdownEnd() {
        hasGameStarted = true
        logicEngine.startTick()
    }
}

// MARK: PauseButtonDelegate
extension GameScene: PauseButtonDelegate {
    func pauseButtonTouched() {
        guard !isGamePaused else {
            return
        }
        isGamePaused = true
        if !gameState.isMultiplayer {
            logicEngine.stopTick()
            countdownNode.reset()
        }
        removeGestureRecognizers()
        
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

        if gameState.isMultiplayer {
            hasGameStarted = true
            logicEngine.startTick()
        } else {
            hasGameStarted = false
            if countdownNode.parent == nil {
                grid.addChild(countdownNode)
            }
            countdownNode.start()
        }
        
        addGestureRecognizers()
    }
    
    func leaveGameSelected() {
        logicEngine.stopTick()
        if gameState.isMultiplayer {
            if gameState.myPlayer.state != .Lost {
                logicEngine.sendPlayerLostData()
            }
            GameNetworkPortal._instance.disconnectFromRoom()
        }
        NSNotificationCenter.defaultCenter().postNotificationName("exitGame", object: nil)
    }
}