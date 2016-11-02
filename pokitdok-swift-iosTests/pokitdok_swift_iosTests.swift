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
        let client = Pokitdok(clientId: client_id, clientSecret: client_secret, basePath: base, autoRefresh: true)
        
//        let response = client.icdConvert(code: "556.9")
//        print("RESPONSE FROM ICD: \(response)")

//        let cash_args = ["zip_code" : "29485", "cpt_code" : "99385"]
//        let cash_response = client.cashPrices(cashPricesRequest: cash_args)
//        print("RESPONSE FROM CLIENT: \(cash_response)")
        
        let elig_args = ["member": [
                            "birth_date" : "1970-01-25",
                            "first_name" : "Jane",
                            "last_name" : "Doe",
                            "id": "W000000000"],
                         "provider": [
                            "first_name" : "JEROME",
                            "last_name" : "AYA-AY",
                            "npi" : "1467560003"],
                         "trading_partner_id": "MOCKPAYER"] as [String : Any]
        let elig_response = client.eligibility(eligibilityRequest: elig_args)
        print("RESPONSE FROM CLIENT: \(elig_response)")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
