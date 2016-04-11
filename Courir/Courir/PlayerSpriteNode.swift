//
//  PlayerSpriteNode.swift
//  Courir
//
//  Created by Sebastian Quek on 6/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

class PlayerSpriteNode: SKSpriteNode {
    
    // ==============================================
    // Static variables and methods
    // ==============================================
    
    static let firstZPosition: CGFloat = 10

    static private let size = CGSize(width: 160, height: 160)
    static private let plumbobSize = CGSize(width: 28, height: 28)
    static private let plumbobPosition = CGPoint(x: 90, y: 180)
    static private let maxColorBlendFactor: CGFloat = 0.8
    static private let invulnerableAlpha: CGFloat = 0.5    
    
    static private var hasInitTextures = false
    static private var playerRunningFrames = [SKTexture]()
    static private var playerJumpingFrames = [SKTexture]()
    static private var playerDuckingFrames = [SKTexture]()
    static private var playerStationaryFrames = [SKTexture]()
    static private var plumbobFrames = [SKTexture]()
    
    static private func initTextures() {
        
        func populateFrames(atlas: SKTextureAtlas,
                            inout frames: [SKTexture],
                            textureBaseName: String) {
            
            for i in 0..<atlas.textureNames.count {
                frames.append(atlas.textureNamed("\(textureBaseName)\(i)"))
            }
        }
        
        populateFrames(playerRunningAtlas,
                       frames: &playerRunningFrames, textureBaseName: "running")
        populateFrames(playerJumpingAtlas,
                       frames: &playerJumpingFrames, textureBaseName: "jumping")
        populateFrames(playerDuckingAtlas,
                       frames: &playerDuckingFrames, textureBaseName: "ducking")
        populateFrames(playerStationaryAtlas,
                       frames: &playerStationaryFrames, textureBaseName: "stationary")
        populateFrames(plumbobAtlas,
                       frames: &plumbobFrames, textureBaseName: "plumbob")
        
        hasInitTextures = true
    }
    
    
    // ==============================================
    // Instance variables and methods
    // ==============================================
    
    private var currentAnimationStep = 0
    private var currentAnimationFrames = [SKTexture]()
    var currentState = PhysicalState.Stationary {
        didSet {
            currentAnimationStep = 0
            
            switch currentState {
            case .Running(_):
                currentAnimationFrames = PlayerSpriteNode.playerRunningFrames
            case .Jumping(_):
                currentAnimationFrames = PlayerSpriteNode.playerJumpingFrames
            case .Ducking(_):
                currentAnimationFrames = PlayerSpriteNode.playerDuckingFrames
            case .Invulnerable(_):
                currentAnimationFrames = PlayerSpriteNode.playerRunningFrames
            case .Stationary(_):
                currentAnimationFrames = PlayerSpriteNode.playerStationaryFrames
            }
        }
    }
    
    private var isMe: Bool
    private var currentPlumbobStep = 0
    private var plumbob: SKSpriteNode?
    
    init(player: Player, isMe: Bool) {
        if !PlayerSpriteNode.hasInitTextures {
            PlayerSpriteNode.initTextures()
        }
        
        currentState = player.physicalState
        self.isMe = isMe
        
        super.init(texture: PlayerSpriteNode.playerStationaryFrames.first,
                   color: UIColor.clearColor(),
                   size: PlayerSpriteNode.size)
        player.observer = self
        
        // Set position of player sprite node
        position = IsoViewConverter.calculateRenderPositionFor(player)
        anchorPoint = CGPointMake(0, 0)
        zPosition = PlayerSpriteNode.firstZPosition - CGFloat(player.playerNumber)
        
        // Add plumbob if player is myself
        if isMe {
            plumbob = SKSpriteNode(texture: PlayerSpriteNode.plumbobFrames.first,
                                   size: PlayerSpriteNode.plumbobSize)
            plumbob?.color = UIColor.redColor()
            plumbob?.colorBlendFactor = 0
            plumbob?.position = PlayerSpriteNode.plumbobPosition
            self.addChild(plumbob!)
        }
    }
    
    /// Updates player sprite to show the next animation frame
    func showNextAnimationFrame() {
        updatePlumbobAnimation()
        updatePlayerAnimation()
    }
    
    private func updatePlumbobAnimation() {
        guard isMe else {
            return
        }
        
        plumbob?.texture = PlayerSpriteNode.plumbobFrames[currentPlumbobStep]
        currentPlumbobStep = (currentPlumbobStep + 1) % PlayerSpriteNode.plumbobFrames.count
    }
    
    private func updatePlayerAnimation() {
        switch currentState {
        case .Invulnerable(_):
            alpha = PlayerSpriteNode.invulnerableAlpha
        default:
            alpha = 1
        }
        texture = currentAnimationFrames[currentAnimationStep]
        currentAnimationStep = (currentAnimationStep + 1) % currentAnimationFrames.count
    }
    
    /// Updates player sprite's plumbob color; plumbob becomes red when player's x coordinate is 0
    private func updatePlumbobColor(playerXCoordinate: Int) {
        plumbob?.colorBlendFactor =
            PlayerSpriteNode.maxColorBlendFactor
            - (CGFloat(playerXCoordinate) / CGFloat(Player.spawnXCoordinate))
            * PlayerSpriteNode.maxColorBlendFactor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PlayerSpriteNode: Observer {
    func didChangeProperty(propertyName: String, from: AnyObject?) {
        guard let player = from as? Player else {
            return
        }
        dispatch_async(dispatch_get_main_queue()) {
            switch propertyName {
            case "xCoordinate", "yCoordinate":
                self.position = IsoViewConverter.calculateRenderPositionFor(player)
                self.updatePlumbobColor(player.xCoordinate)
            case "physicalState":
                self.currentState = player.physicalState
            default:
                return
            }
        }
    }
}