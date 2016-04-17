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
        let g1 = ObstacleGenerator(seed: "".dataUsingEncoding(NSUTF8StringEncoding))
        let g2 = ObstacleGenerator(seed: "".dataUsingEncoding(NSUTF8StringEncoding))
        XCTAssertFalse(generatesSameSequence(g1, g2),
                      "Valid generators should result with same values")
    }
    
    func testSeed_singleChar() {
        var g1 = ObstacleGenerator(seed: "a".dataUsingEncoding(NSUTF8StringEncoding))
        var g2 = ObstacleGenerator(seed: "a".dataUsingEncoding(NSUTF8StringEncoding))
        XCTAssertTrue(generatesSameSequence(g1, g2),
                      "Valid generators should result with same values")
        
        g1 = ObstacleGenerator(seed: "1".dataUsingEncoding(NSUTF8StringEncoding))
        g2 = ObstacleGenerator(seed: "1".dataUsingEncoding(NSUTF8StringEncoding))
        XCTAssertTrue(generatesSameSequence(g1, g2),
                      "Valid generators should result with same values")
    }
    
    func testSeed_multipleChar() {
        var g1 = ObstacleGenerator(seed: "Courir".dataUsingEncoding(NSUTF8StringEncoding))
        var g2 = ObstacleGenerator(seed: "Courir".dataUsingEncoding(NSUTF8StringEncoding))
        XCTAssertTrue(generatesSameSequence(g1, g2),
                      "Valid generators should result with same values")
        
        g1 = ObstacleGenerator(seed: "Coulomb".dataUsingEncoding(NSUTF8StringEncoding))
        g2 = ObstacleGenerator(seed: "Coulomb".dataUsingEncoding(NSUTF8StringEncoding))
        XCTAssertTrue(generatesSameSequence(g1, g2),
                      "Valid generators should result with same values")
    }
    
    func testSeed_multipleSpecialChar() {
        var g1 = ObstacleGenerator(seed: "Courir, best Courir!".dataUsingEncoding(NSUTF8StringEncoding))
        var g2 = ObstacleGenerator(seed: "Courir, best Courir!".dataUsingEncoding(NSUTF8StringEncoding))
        XCTAssertTrue(generatesSameSequence(g1, g2),
                      "Valid generators should result with same values")
        
        g1 = ObstacleGenerator(seed: "~`!@#$%^&*()_+ Coulomb".dataUsingEncoding(NSUTF8StringEncoding))
        g2 = ObstacleGenerator(seed: "~`!@#$%^&*()_+ Coulomb".dataUsingEncoding(NSUTF8StringEncoding))
        XCTAssertTrue(generatesSameSequence(g1, g2),
                      "Valid generators should result with same values")
    }
    
    func testSeed_differentStrings() {
        var g1 = ObstacleGenerator(seed: "Courir".dataUsingEncoding(NSUTF8StringEncoding))
        var g2 = ObstacleGenerator(seed: "Coulomb".dataUsingEncoding(NSUTF8StringEncoding))
        XCTAssertFalse(generatesSameSequence(g1, g2),
                       "Valid & different generators should result with different values")
        
        g1 = ObstacleGenerator(seed: "~`!@#$%^&*()_+ Coulomb".dataUsingEncoding(NSUTF8StringEncoding))
        g2 = ObstacleGenerator(seed: "Coulomb ~`!@#$%^&*()_+".dataUsingEncoding(NSUTF8StringEncoding))
        XCTAssertFalse(generatesSameSequence(g1, g2),
                       "Valid & different generators should result with different values")
    }
    
    /// Compare output obstacle types with predefined expected output
    func testGetNextObstacleIsDeterministic() {
        let g1 = ObstacleGenerator(seed: "Courir".dataUsingEncoding(NSUTF8StringEncoding))
        let expected1: [ObstacleType?] = [nil, nil, nil, nil, ObstacleType.Floating]
        for i in 0..<5 {
//            print(g1.getNextObstacle()?.type)
            XCTAssertTrue(g1.getNextObstacle()?.type == expected1[i], "Non deterministic")
        }
        print()
        let g2 = ObstacleGenerator(seed: "Coulomb x Courir".dataUsingEncoding(NSUTF8StringEncoding))
        let expected2: [ObstacleType?] = [nil, nil, nil,  ObstacleType.Floating, nil]
        for i in 0..<5 {
//            print(g2.getNextObstacle()?.type)
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
