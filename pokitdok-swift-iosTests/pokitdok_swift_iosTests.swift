//
//  pokitdok_swift_iosTests.swift
//  pokitdok-swift-iosTests
//
//  Created by Charlie Thiry on 10/28/16.
//  Copyright © 2016 Charlie Thiry. All rights reserved.
//

import XCTest
@testable import Pokitdok

class pokitdok_swift_iosTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let client_id = "9P10N4H2F7ZbaAU6RYct"
        let client_secret = "gOFzgJiIUoqnUhjaZezDxUf7ugPF6FsRAPy2tWDT"
        let base = "http://localhost:5002"
        var client = Pokitdok(clientId: client_id, clientSecret: client_secret, basePath: base, autoRefresh: true)
        
        client.icdConvert(code: "556.9")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
