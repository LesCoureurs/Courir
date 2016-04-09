//
//  GameScene+Observer.swift
//  Courir
//
//  Created by Sebastian Quek on 3/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

extension GameScene: Observer {
    
    // ==============================================
    // MARK: Overridden methods
    // ==============================================
    
    func didChangeProperty(propertyName: String, from: AnyObject?) {
        if let _ = from as? GameState {
            handleUpdateGameState(propertyName)
        } else if let object = from as? Environment {
            handleUpdateEnvironment(object, propertyName: propertyName)
        }
    }
    
    
    /// Update screen coordinates for object whose x and/or y coordinate has changed
    private func updatePositionFor(object: GameObject, withNode node: SKSpriteNode) {
        node.position = IsoViewConverter.calculateRenderPositionFor(object)
    }

    
    // ==============================================
    // MARK: Methods for observing GameState
    // ==============================================
    
    /// Handle the updating of appropriate nodes when changes are made to the game state
    private func handleUpdateGameState(propertyName: String) {
        switch propertyName {
            case "gameIsOver":
                gameDidEnd()
            case "obstacles":
                handleChangesToObstacles()
            case "distance":
                updateScore()
            default:
                return
        }
    }
    
    private func gameDidEnd() {
        let gameOverData = [
            "eventRawValue": GameEvent.GameDidEnd.rawValue,
            "gameResult": gameState.scoreTracking,
            "ghostStore": gameState.ghostStore
        ]
        
        NSNotificationCenter.defaultCenter()
            .postNotificationName("showEndGameMenu",
                                  object: self,
                                  userInfo: gameOverData as [NSObject : AnyObject])
    }
    
    private func handleChangesToObstacles() {
        
        // Handle newly added obstacles
        let addedObstacles = gameState.obstacles.filter {obstacles[$0.identifier] == nil}
        
        for obstacle in addedObstacles {
            obstacle.observer = self
            obstacles[obstacle.identifier] = createObstacleNode(obstacle)
        }
        
        // Handle removed obstacles
        let obstacleIds = gameState.obstacles.map {$0.identifier}
        let removedObstacles = obstacles.filter {!obstacleIds.contains($0.0)}
        
        for (id, obstacleNode) in removedObstacles {
            obstacleNode.removeFromParent()
            obstacles.removeValueForKey(id)
        }
    }
    
    // Update the score
    private func updateScore() {
        scoreNode.setScore(gameState.distance)
    }
    
    
    // ==============================================
    // MARK: Methods for observing Environment
    // ==============================================
    
    private func handleUpdateEnvironment(environment: Environment, propertyName: String) {
        guard let node = environmentNodes[environment.identifier] else {
            return
        }
        switch propertyName {
            case "xCoordinate", "yCoordinate":
                updatePositionFor(environment, withNode: node)
            case "zPosition":
                node.zPosition = CGFloat(environment.zPosition)
            default:
                return
        }
    }
    
}
