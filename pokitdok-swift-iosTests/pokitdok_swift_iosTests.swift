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

//        let cash_response = client.cashPrices(cptCode: "99385", zipCode: "29485")
//        print("RESPONSE FROM CASH PRICES: \(cash_response)")

//        let elig_args = ["member": [
//                            "birth_date" : "1970-01-25",
//                            "first_name" : "Jane",
//                            "last_name" : "Doe",
//                            "id": "W000000000"],
//                         "provider": [
//                            "first_name" : "JEROME",
//                            "last_name" : "AYA-AY",
//                            "npi" : "1467560003"],
//                         "trading_partner_id": "MOCKPAYER"] as [String : Any]
//        let elig_response = client.eligibility(eligibilityRequest: elig_args)
//        print("RESPONSE FROM ELIGIBILITY: \(elig_response)")
    
        let act_response = client.activities(activityId: "581b6a980640fd74df1e86fc")
        print("RESPONSE FROM ACTIVITIES: \(act_response)")
        
//        let cash_response = client.insurancePrices(cptCode: "99385", zipCode: "29485")
//        print("RESPONSE FROM INSURANCE PRICES: \(cash_response)")
        
//        let response = client.mpc(name: "office")
//        print("RESPONSE FROM MPC: \(response)")
//        
//        let response = client.schedulers(schedulerUuid: "725d65a1-517c-49ca-bbd5-1ad6ddc7086a")
//        print("RESPONSE FROM schedulers: \(response)")

        let price_load_args = ["trading_partner_id": "MOCKPAYER",
                               "cpt_bundle": ["99999", "81291"],
                               "eligibility": ["provider": ["npi": "1912301953",
                                                            "organization_name": "PokitDok, Inc"],
                                               "member": ["birth_date": "1975-04-26",
                                                          "first_name": "Joe",
                                                          "last_name": "Immortan",
                                                          "id": "999999999"]]] as [String : Any]
        let oop_response = client.oopEstimate(oopEstimateRequest: price_load_args)
        print("RESPONSE FROM loadprice: \(oop_response)")
        print(oop_response["data"])
        print((oop_response["data"] as! [String: Any])["calculation"])

        let tp_response = client.tradingPartners()
        print("RESPONSE FROM providers: \(tp_response)")
    }
        
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
