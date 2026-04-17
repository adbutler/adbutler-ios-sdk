import XCTest
@testable import AdButlerSDK

final class AdResponseParsingTests: XCTestCase {
    func testParseSuccessfulImageResponse() throws {
        let json = """
        {
          "status": "SUCCESS",
          "placements": {
            "placement_1": {
              "banner_id": 123456,
              "width": 300,
              "height": 250,
              "image_url": "https://example.com/ad.png",
              "redirect_url": "https://example.com/click",
              "accupixel_url": "https://example.com/impression",
              "eligible_url": "https://example.com/eligible",
              "viewable_url": "https://example.com/viewable",
              "body": "",
              "tracking_pixel": "https://example.com/pixel",
              "refresh_time": 30,
              "alt_text": "Test Ad"
            }
          }
        }
        """.data(using: .utf8)!

        let response = try AdResponse.parseAdServeResponse(data: json)

        XCTAssertEqual(response.bannerId, 123456)
        XCTAssertEqual(response.width, 300)
        XCTAssertEqual(response.height, 250)
        XCTAssertEqual(response.imageUrl, "https://example.com/ad.png")
        XCTAssertEqual(response.redirectUrl, "https://example.com/click")
        XCTAssertEqual(response.accupixelUrl, "https://example.com/impression")
        XCTAssertEqual(response.eligibleUrl, "https://example.com/eligible")
        XCTAssertEqual(response.viewableUrl, "https://example.com/viewable")
        XCTAssertEqual(response.trackingPixel, "https://example.com/pixel")
        XCTAssertEqual(response.refreshTime, 30)
        XCTAssertTrue(response.isImageAd)
        XCTAssertFalse(response.isHtmlAd)
    }

    func testParseHtmlBodyResponse() throws {
        let json = """
        {
          "status": "SUCCESS",
          "placements": {
            "placement_1": {
              "banner_id": 789,
              "width": 320,
              "height": 50,
              "image_url": "",
              "body": "<div>Native Ad Content</div>",
              "redirect_url": "https://example.com/click"
            }
          }
        }
        """.data(using: .utf8)!

        let response = try AdResponse.parseAdServeResponse(data: json)

        XCTAssertEqual(response.bannerId, 789)
        XCTAssertTrue(response.isHtmlAd)
        XCTAssertFalse(response.isImageAd)
        XCTAssertEqual(response.body, "<div>Native Ad Content</div>")
    }

    func testParseNoAdAvailable() {
        let json = """
        {"status": "NO_ADS", "placements": {}}
        """.data(using: .utf8)!

        XCTAssertThrowsError(try AdResponse.parseAdServeResponse(data: json)) { error in
            guard case AdButlerError.noAdAvailable = error else {
                XCTFail("Expected noAdAvailable error")
                return
            }
        }
    }

    func testParseArrayPlacement() throws {
        let json = """
        {
          "status": "SUCCESS",
          "placements": {
            "placement_1": [
              {
                "banner_id": 111,
                "width": 728,
                "height": 90,
                "image_url": "https://example.com/leaderboard.png",
                "redirect_url": "https://example.com/click"
              }
            ]
          }
        }
        """.data(using: .utf8)!

        let response = try AdResponse.parseAdServeResponse(data: json)
        XCTAssertEqual(response.bannerId, 111)
        XCTAssertEqual(response.width, 728)
        XCTAssertEqual(response.height, 90)
    }

    func testParseInvalidJson() {
        let json = "not json".data(using: .utf8)!

        XCTAssertThrowsError(try AdResponse.parseAdServeResponse(data: json))
    }
}
