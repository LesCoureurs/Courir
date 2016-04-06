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
    
    static private var hasInitTextures = false
    static private var playerRunningFrames = [SKTexture]()
    static private var playerJumpingFrames = [SKTexture]()
    static private var playerDuckingFrames = [SKTexture]()
    static private var playerStationaryFrames = [SKTexture]()
    
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
            
            texture = currentAnimationFrames[currentAnimationStep]
        }
    }
    
    init(player: Player) {
        if !PlayerSpriteNode.hasInitTextures {
            PlayerSpriteNode.initTextures()
        }
        
        currentState = player.physicalState
        
        super.init(texture: PlayerSpriteNode.playerStationaryFrames.first,
                   color: UIColor.clearColor(),
                   size: CGSize(width: 160, height: 160))
        
        position = IsoViewConverter.calculateRenderPositionFor(player)
        anchorPoint = CGPointMake(0, 0)
        zPosition = 2
    }
    
    func showNextAnimationFrame() {
        currentAnimationStep = (currentAnimationStep + 1) % currentAnimationFrames.count
        texture = currentAnimationFrames[currentAnimationStep]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}