//
//  ObstacleGenerator.swift
//  Courir
//
//  Created by Sebastian Quek on 19/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import GameplayKit

class ObstacleGenerator {
    
    private let source: GKARC4RandomSource
    
    init(seed: String? = nil) {
        var seed = seed
        if seed != nil {
            source = GKARC4RandomSource(seed: NSData(bytes: &seed, length: sizeof(Int)))
        } else {
            source = GKARC4RandomSource()
        }
    }
    
    func getNextObstacle(type: ObstacleType? = nil) -> Obstacle? {
        if let type = type {
            return Obstacle(type: type)
        }
        
        let nextRandFloat = source.nextUniform()
        switch nextRandFloat {
            case 0..<floatingProbability:
                return Obstacle(type: ObstacleType.Floating)
            case floatingProbability..<floatingProbability + nonfloatingProbability:
                return Obstacle(type: ObstacleType.NonFloating)
            default:
                return nil
        }
    }
}
