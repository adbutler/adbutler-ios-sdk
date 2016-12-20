//
//  IntegrationTests.swift
//  AdButler
//
//  Created by Ryuichi Saito on 12/19/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import XCTest

@testable import AdButler

class IntegrationTests: XCTestCase {
    
    func testSamples() {
        AdButler.session = Session().urlSession
        let expct = expectation(description: "expect to get a response")
        AdButler.requestPlacement(with: PlacementRequestConfig(accountId: 153105, zoneId: 214764, width: 300, height: 250, keywords: ["sample2"])) { (response) in
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
            XCTAssertEqual(placement.bannerId, 519407754)
            XCTAssertTrue(placement.redirectUrl?.hasPrefix("https://servedbyadbutler.com/redirect.spark?MID=153105&plid=550986&setID=214764&channelID=0&CID=0&banID=519407754&PID=0&textadID=0&tc=1") ?? false)
            XCTAssertEqual(placement.imageUrl, "https://servedbyadbutler.com/default_banner.gif")
            XCTAssertEqual(placement.width, 300)
            XCTAssertEqual(placement.height, 250)
            XCTAssertEqual(placement.altText, "")
            XCTAssertEqual(placement.target, "_blank")
            XCTAssertEqual(placement.trackingPixel, "https://servedbyadbutler.com/default_banner.gif?foo=bar&demo=fakepixel")
            XCTAssertTrue(placement.accupixelUrl?.hasPrefix("https://servedbyadbutler.com/adserve.ibs/;ID=153105;size=1x1;type=pixel;setID=214764;") ?? false)
            XCTAssertNil(placement.refreshUrl)
            XCTAssertNil(placement.refreshTime)
            XCTAssertNil(placement.body)
        }
        waitForExpectations(timeout: 10)
    }
    
}
