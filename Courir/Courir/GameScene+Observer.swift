//
//  GameScene+Observer.swift
//  Courir
//
//  Created by Sebastian Quek on 3/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

extension GameScene: Observer {
    
    // MARK: Overridden methods
    
    func didChangeProperty(propertyName: String, from: AnyObject?) {
        if let object = from as? Player {
            handleUpdatePlayerNode(object, propertyName: propertyName)
        } else if let object = from as? Obstacle {
            handleUpdateObstacleNode(object, propertyName: propertyName)
        } else if let _ = from as? GameState {
            handleUpdateGameState(propertyName)
        }
    }
    
    
    // MARK: Methods for observing Players
    
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
        case "physicalState":
            updatePlayerTexture(player, withNode: node)
        case "state":
            updateState(player, withNode: node)
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
    
    private func updateState(player: Player, withNode node: SKSpriteNode) {
        switch player.state {
        case .Lost:
            // TODO handle updates to player states
            break;
        default:
            return
        }
    }
    
    
    // MARK: Methods for observing Obstacles
    
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
    
    
    // MARK: Methods for observing GameState
    
    /// Handle the updating of appropriate nodes when changes are made to the game state
    private func handleUpdateGameState(propertyName: String) {
        switch propertyName {
        case "gameIsOver":
            gameDidEnd()
        case "obstacles":
            handleChangesToObstacles()
        default:
            return
        }
    }
    
    private func gameDidEnd() {
        let gameOverData = ["eventRawValue": GameEvent.GameDidEnd.rawValue, "gameResult": gameState.scoreTracking]
        
        NSNotificationCenter.defaultCenter().postNotificationName("showEndGameMenu", object: self, userInfo: gameOverData as [NSObject : AnyObject])
        print("Game did end. Score tracking: \(gameState.scoreTracking)")
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
}
