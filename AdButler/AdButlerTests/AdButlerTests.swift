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
    private let placement1 = [
        "banner_id": "1",
        "redirect_url": "https://servedbyadbutler.com/redirect.spark?MID=153105&plid=543820&setID=214764&channelID=0&CID=0&banID=519401954&PID=0&textadID=0&tc=1&mt=1482121253469173&hc=fdc53f2a708e63ffd71bf224471433202cd31416&location=",
        "image_url": "https://servedbyadbutler.com/default_banner.gif",
        "width": "300",
        "height": "250",
        "alt_text": "",
        "target": "_blank",
        "tracking_pixel": "",
        "accupixel_url": "https://servedbyadbutler.com/adserve.ibs/;ID=153105;size=1x1;type=pixel;setID=214764;plid=543820;BID=519401954;wt=1482121263;rnd=99929",
        "refresh_url": "",
        "refresh_time": "",
        "body": ""
    ]
    
    private let placement2 = [
        "banner_id": "2",
        "redirect_url": "https://servedbyadbutler.com/redirect.spark?MID=153105&plid=550986&setID=214764&channelID=0&CID=0&banID=519407754&PID=0&textadID=0&tc=1&mt=1482121259961736&hc=81916f6603f91c20aecb6693d4a38ad9f632db6f&location=",
        "image_url": "https://servedbyadbutler.com/default_banner.gif",
        "width": "300",
        "height": "250",
        "alt_text": "",
        "target": "_blank",
        "tracking_pixel": "https://servedbyadbutler.com/default_banner.gif?foo=bar&demo=fakepixel",
        "accupixel_url": "https://servedbyadbutler.com/adserve.ibs/;ID=153105;size=1x1;type=pixel;setID=214764;plid=550986;BID=519407754;wt=1482121269;rnd=44297",
        "refresh_url": "",
        "refresh_time": "",
        "body": ""]
    
    func testRequestPlacement() {
        AdButler.session = TestSession.success(placement1).session
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
            XCTAssertEqual(placement.bannerId, 1)
        }
        waitForExpectations(timeout: 3)
    }
    
    func testRequestMultiplePlacements() {
        AdButler.session = TestSession.success(placement2).session
        let config = PlacementRequestConfig(accountId: 153105, zoneId: 214764, width: 300, height: 250, keywords: ["keyword2"], click: "foo")
        let expct = expectation(description: "expect to get a response")
        AdButler.requestPlacements(with: [config, config]) { (response) in
            expct.fulfill()
            
            guard case let .success(status, placements) = response else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(status.rawValue, "SUCCESS")
            guard placements.count == 2 else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(placements[0].bannerId, 2)
            XCTAssertEqual(placements[1].bannerId, 2)
        }
        waitForExpectations(timeout: 3)
    }
    
    func testBadRequest() {
        AdButler.session = TestSession.badRequest(400).session
        let config = PlacementRequestConfig(accountId: 153105, zoneId: 214764, width: 300, height: 250)
        let expct = expectation(description: "expect to get a response")
        AdButler.requestPlacement(with: config) { (response) in
            expct.fulfill()
            
            guard case let .badRequest(statusCode?, body?) = response else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(statusCode, 400)
            XCTAssertEqual(body, "bad request")
        }
        waitForExpectations(timeout: 3)
    }
    
    func testInvalidJSON() {
        AdButler.session = TestSession.invalidJson.session
        let config = PlacementRequestConfig(accountId: 153105, zoneId: 214764, width: 300, height: 250)
        let expct = expectation(description: "expect to get a response")
        AdButler.requestPlacement(with: config) { (response) in
            expct.fulfill()
            
            guard case let .invalidJson(body?) = response else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(body, "invalid json")
        }
        waitForExpectations(timeout: 3)
    }
    
    func testRequestError() {
        AdButler.session = TestSession.requestError.session
        let config = PlacementRequestConfig(accountId: 153105, zoneId: 214764, width: 300, height: 250)
        let expct = expectation(description: "expect to get a response")
        AdButler.requestPlacement(with: config) { (response) in
            expct.fulfill()
            
            guard case let .requestError(error) = response else {
                XCTFail()
                return
            }
            
            XCTAssertTrue(error is TestError)
        }
        waitForExpectations(timeout: 3)
    }
    
    func testRequestPixel() {
        let pixelSession = TestSession.requestPixel.session as! RequestPixelSession
        XCTAssertFalse(pixelSession.isResumeCalled)
        AdButler.session = pixelSession
        AdButler.requestPixel(with: URL(string: "https://servedbyadbutler.com")!)
        XCTAssertTrue(pixelSession.isResumeCalled)
    }
    
    func testRecordImpression() {
        let pixelSession = TestSession.requestPixel.session as! RequestPixelSession
        XCTAssertFalse(pixelSession.isResumeCalled)
        AdButler.session = pixelSession
        let placement = Placement(from: placement1)
        placement?.recordImpression()
        XCTAssertTrue(pixelSession.isResumeCalled)
    }
    
    func testRecordClick() {
        let pixelSession = TestSession.requestPixel.session as! RequestPixelSession
        XCTAssertFalse(pixelSession.isResumeCalled)
        AdButler.session = pixelSession
        let placement = Placement(from: placement2)
        placement?.recordClick()
        XCTAssertTrue(pixelSession.isResumeCalled)
    }
}
