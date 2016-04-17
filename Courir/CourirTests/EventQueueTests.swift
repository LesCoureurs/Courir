//
//  EventQueueTests.swift
//  Courir
//
//  Created by Ian Ngiaw on 4/17/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

@testable import Courir
import XCTest

class EventQueueTests: XCTestCase {
    
    static let event1: EventQueue.Element = (GameEvent.PlayerDidJump, 1, 1, nil)
    static let event2: EventQueue.Element = (GameEvent.PlayerDidDuck, 1, 2, nil)
    static let event3: EventQueue.Element = (GameEvent.PlayerDidJump, 1, 3, nil)
    static let event4: EventQueue.Element = (GameEvent.PlayerDidJump, 1, 4, nil)
    static let initalEvents = [event4, event2, event3, event1]

    func testInitEmpty() {
        let queue = EventQueue()
        XCTAssertEqual(queue.count, 0,
                       "Initializing event queue with empty constructor should be empty")
        XCTAssertNil(queue.head,
                     "Initializing event queue with empty constructor should be not have head")
    }
    
    func testInitNonEmpty() {
        let queue = EventQueue(initialEvents: EventQueueTests.initalEvents)
        XCTAssertEqual(queue.count, 4,
                       "Initializing event queue with 4 initial events should have 4 items")
        XCTAssertEqual(queue.head?.timeStep, 1,
                       "Initializing event queue with 4 initial events should have head with timeStep 1")
    }
    
    func testInsert() {
        let queue = EventQueue()
        queue.insert(.PlayerDidJump, playerNumber: 1, timeStep: 3, otherData: nil)
        XCTAssertEqual(queue.count, 1, "EventQueue should have 1 item after first insertion")
        XCTAssertEqual(queue.head?.timeStep, 3, "EventQueue head should be 3 after first insertion")
        
        queue.insert(.PlayerDidDuck, playerNumber: 1, timeStep: 2, otherData: nil)
        XCTAssertEqual(queue.count, 2, "EventQueue should have 2 items after second insertion")
        XCTAssertEqual(queue.head?.timeStep, 2,
                       "EventQueue head should be 2 after second insertion")
        
        queue.insert(.PlayerDidJump, playerNumber: 1, timeStep: 4, otherData: nil)
        XCTAssertEqual(queue.count, 3, "EventQueue should have 3 items after third insertion")
        XCTAssertEqual(queue.head?.timeStep, 2,
                       "EventQueue head should still be 2 after third insertion")
    }
    
    func testHead() {
        let queue = EventQueue()
        XCTAssertNil(queue.head, "Empty queue's head should be nil")
        
        let queue2 = EventQueue(initialEvents: EventQueueTests.initalEvents)
        XCTAssertEqual(queue2.head?.timeStep, 1, "Non-empty queue's head should be 1")
        
        queue2.removeHead()
        XCTAssertEqual(queue2.head?.timeStep, 2, "Non-empty queue's head should be 2 after removal")
    }
    
    func testCount() {
        let queue = EventQueue()
        XCTAssertEqual(queue.count, 0, "Empty queue's count should be 0")
        
        let queue2 = EventQueue(initialEvents: EventQueueTests.initalEvents)
        XCTAssertEqual(queue2.count, 4, "Non-empty queue's count should be 4")
        
        queue2.removeHead()
        XCTAssertEqual(queue2.count, 3, "Non-empty queue's count should be 3 after removal")
    }
    
    func testRemoveHead() {
        let queue = EventQueue()
        XCTAssertNil(queue.removeHead(), "Removing head from empty queue should return nil")
        
        let queue2 = EventQueue(initialEvents: EventQueueTests.initalEvents)
        XCTAssertEqual(queue2.removeHead()?.timeStep, 1,
                       "Removing head from non-empty queue should return event with timeStep 1")
        XCTAssertEqual(queue2.removeHead()?.timeStep, 2,
                       "Removing head again from non-empty queue should return event with timeStep 2")
        XCTAssertEqual(queue2.removeHead()?.timeStep, 3,
                       "Removing head third time from non-empty queue should return event with timeStep 3")
        
        queue2.insert(.PlayerDidDuck, playerNumber: 1, timeStep: 1, otherData: nil)
        XCTAssertEqual(queue2.removeHead()?.timeStep, 1,
                       "Removing head after insertion should return event with timeStep 1")
    }

}
