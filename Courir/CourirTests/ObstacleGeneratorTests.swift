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
    
    func testSeed_blank() {
        let g1 = ObstacleGenerator(seed: "")
        let g2 = ObstacleGenerator(seed: "")
        XCTAssertFalse(generatesSameSequence(g1, g2),
                      "Valid generators should result with same values")
    }
    
    func testSeed_singleChar() {
        var g1 = ObstacleGenerator(seed: "a")
        var g2 = ObstacleGenerator(seed: "a")
        XCTAssertTrue(generatesSameSequence(g1, g2),
                      "Valid generators should result with same values")
        
        g1 = ObstacleGenerator(seed: "1")
        g2 = ObstacleGenerator(seed: "1")
        XCTAssertTrue(generatesSameSequence(g1, g2),
                      "Valid generators should result with same values")
    }
    
    func testSeed_multipleChar() {
        var g1 = ObstacleGenerator(seed: "Courir")
        var g2 = ObstacleGenerator(seed: "Courir")
        XCTAssertTrue(generatesSameSequence(g1, g2),
                      "Valid generators should result with same values")
        
        g1 = ObstacleGenerator(seed: "Coulomb")
        g2 = ObstacleGenerator(seed: "Coulomb")
        XCTAssertTrue(generatesSameSequence(g1, g2),
                      "Valid generators should result with same values")
    }
    
    func testSeed_multipleSpecialChar() {
        var g1 = ObstacleGenerator(seed: "Courir, best Courir!")
        var g2 = ObstacleGenerator(seed: "Courir, best Courir!")
        XCTAssertTrue(generatesSameSequence(g1, g2),
                      "Valid generators should result with same values")
        
        g1 = ObstacleGenerator(seed: "~`!@#$%^&*()_+ Coulomb")
        g2 = ObstacleGenerator(seed: "~`!@#$%^&*()_+ Coulomb")
        XCTAssertTrue(generatesSameSequence(g1, g2),
                      "Valid generators should result with same values")
    }
    
    func testSeed_differentStrings() {
        var g1 = ObstacleGenerator(seed: "Courir")
        var g2 = ObstacleGenerator(seed: "Coulomb")
        XCTAssertFalse(generatesSameSequence(g1, g2),
                       "Valid & different generators should result with different values")
        
        g1 = ObstacleGenerator(seed: "~`!@#$%^&*()_+ Coulomb")
        g2 = ObstacleGenerator(seed: "Coulomb ~`!@#$%^&*()_+")
        XCTAssertFalse(generatesSameSequence(g1, g2),
                       "Valid & different generators should result with different values")
    }
    
    /// Compare output obstacle types with predefined expected output
    func testGetNextObstacleIsDeterministic() {
        let g1 = ObstacleGenerator(seed: "seed")
        let expected1: [ObstacleType?] = [nil, nil, ObstacleType.Floating, nil, nil]
        for i in 0..<5 {
            XCTAssertTrue(g1.getNextObstacle()?.type == expected1[i], "Non deterministic")
        }
        
        let g2 = ObstacleGenerator(seed: "another seed")
        let expected2: [ObstacleType?] = [nil, nil, nil, nil, ObstacleType.NonFloating]
        for i in 0..<5 {
            XCTAssertTrue(g2.getNextObstacle()?.type == expected2[i], "Non deterministic")
        }
    }
    
    /// Test if specifying the type of getNextObstacle returns the correct type
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
