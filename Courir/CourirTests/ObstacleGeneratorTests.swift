//
//  ObstacleGeneratorTests.swift
//  Courir
//
//  Created by Sebastian Quek on 25/3/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

@testable import Courir
import XCTest

class ObstacleGeneratorTests: XCTestCase {
    private let numberOfGenerations = 100
    
    private func generatesSameSequence(g1: ObstacleGenerator, _ g2: ObstacleGenerator) -> Bool {
        for _ in 0..<numberOfGenerations {
            if g1.getNextObstacle()?.type != g2.getNextObstacle()?.type {
                return false
            }
        }
        return true
    }

    func testNoSeed() {
        var g1 = ObstacleGenerator()
        var g2 = ObstacleGenerator()
        XCTAssertFalse(generatesSameSequence(g1, g2),
                       "Generators with no seed should not result with same values")
        
        g1 = ObstacleGenerator(seed: nil)
        g2 = ObstacleGenerator(seed: nil)
        XCTAssertFalse(generatesSameSequence(g1, g2),
                       "Generators with no seed should not result with same values")
    }
    
    func testSeed_zero() {
        let g1 = ObstacleGenerator(seed: 0)
        let g2 = ObstacleGenerator(seed: 0)
        XCTAssertTrue(generatesSameSequence(g1, g2),
                      "Valid generators should result with same values")
    }
    
    func testSeed_maxInt() {
        let g1 = ObstacleGenerator(seed: Int.max)
        let g2 = ObstacleGenerator(seed: Int.max)
        XCTAssertTrue(generatesSameSequence(g1, g2),
                      "Valid generators should result with same values")
    }
    
    func testSeed_negativeInt() {
        let g1 = ObstacleGenerator(seed: -5)
        let g2 = ObstacleGenerator(seed: -5)
        XCTAssertTrue(generatesSameSequence(g1, g2),
                      "Valid generators should result with same values")
    }
    
    func testSeed_differentInts() {
        var g1 = ObstacleGenerator(seed: 555)
        var g2 = ObstacleGenerator(seed: -123)
        XCTAssertFalse(generatesSameSequence(g1, g2),
                       "Valid & different generators should result with different values")
        
        g1 = ObstacleGenerator(seed: 12351535)
        g2 = ObstacleGenerator(seed: 12351534)
        XCTAssertFalse(generatesSameSequence(g1, g2),
                       "Valid & different generators should result with different values")
    }
    
    func testGetNextObstacleIsDeterministic() {
        let g1 = ObstacleGenerator(seed: 1)
        let expected1: [ObstacleType?] = [nil, ObstacleType.NonFloating, nil, nil, ObstacleType.NonFloating]
        for i in 0..<5 {
            XCTAssertTrue(g1.getNextObstacle()?.type == expected1[i], "Non deterministic")
        }
        
        let g2 = ObstacleGenerator(seed: 999)
        let expected2: [ObstacleType?] = [nil, ObstacleType.NonFloating, nil, ObstacleType.Floating, nil]
        for i in 0..<5 {
            XCTAssertTrue(g2.getNextObstacle()?.type == expected2[i], "Non deterministic")
        }
    }
    
    func testGetNextObstacleWithType() {
        let g1 = ObstacleGenerator()
        XCTAssertEqual(g1.getNextObstacle(ObstacleType.Floating)!.type,
                       ObstacleType.Floating, "Should force floating obstacle type")
        XCTAssertNotEqual(g1.getNextObstacle(ObstacleType.Floating)!.type,
                          ObstacleType.NonFloating, "Should force floating obstacle type")
        
        XCTAssertEqual(g1.getNextObstacle(ObstacleType.NonFloating)!.type,
                       ObstacleType.NonFloating, "Should force non floating obstacle type")
        XCTAssertNotEqual(g1.getNextObstacle(ObstacleType.NonFloating)!.type,
                          ObstacleType.Floating, "Should force non floating obstacle type")
    }
}
