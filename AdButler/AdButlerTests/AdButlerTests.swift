//
//  AdButlerTests.swift
//  AdButlerTests
//
//  Created by Ryuichi Saito on 12/14/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import XCTest

@testable import AdButler

class AdButlerTests: XCTestCase {
    func testRequest() {
        AdButler.session = TestSession.sample1.session
        let config = PlacementRequestConfig(accountId: 153105, zoneId: 214764, width: 300, height: 250)
        let expct = expectation(description: "expect to get a response")
        AdButler.requestPlacement(with: config) { (response) in
            expct.fulfill()
            
            guard case let .success(status, placements) = response else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(status.rawValue, "SUCCESS")
            guard placements.count == 1 else {
                XCTFail()
                return
            }
            
            let placement = placements[0]
            XCTAssertEqual(placement.bannerId, 519401954)
        }
        waitForExpectations(timeout: 3)
    }
}
