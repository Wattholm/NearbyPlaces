//
//  NearbyPlacesTests.swift
//  NearbyPlacesTests
//
//  Created by KJEM on 11/01/2020.
//  Copyright © 2020 KJEM. All rights reserved.
//

import XCTest
import Moya
import SwiftyJSON
@testable import NearbyPlaces

class NearbyPlacesTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testNetworkDataCall() {
        
        // Given:
        let coord = (lat: 51.5074, lon: 0.1278 ) // London's coordinates
        let provider = MoyaProvider<Places>(stubClosure: MoyaProvider.delayedStub(1.0))
        let target: Places = .browse(lat: coord.lat, lon: coord.lon, radius: PlacesConstants.searchRadius, category: nil, size: PlacesConstants.maxResultSize)
        var json: JSON? = nil
        var errorObject: Error?
        let expectation = self.expectation(description: #function)

        // When:
        provider.request(target) { (result) in
            expectation.fulfill()
            switch result {
            case .success(let moyaResponse):
                do {
                    let data = moyaResponse.data
                    json = try JSON(data: data)
                    print(json?.string ?? "")
                } catch(let err) {
                    errorObject = err
                    XCTFail(err.localizedDescription)
                }
            case .failure(let err):
                errorObject = err
                XCTFail(err.errorDescription ?? "Failed with unknown error")
            }
        }
     
        // Then:
        waitForExpectations(timeout: 10)
        XCTAssert(json != nil, "JSON response data should not be nil.")
        XCTAssert(json!["results"]["items"].exists(), "Result items should exist.")
        print("Number of result items: \(json!["results"]["items"].count)")
        XCTAssert(json!["results"]["items"].count == 10, "There should be 10 results.")
        print(json!)
        print(errorObject?.localizedDescription ?? "")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
