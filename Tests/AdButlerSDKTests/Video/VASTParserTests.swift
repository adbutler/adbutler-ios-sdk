import XCTest
@testable import AdButlerSDK

final class VASTParserTests: XCTestCase {
    func testParseVAST42() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <VAST version="4.2">
          <Ad id="ad-001" sequence="1">
            <InLine>
              <AdSystem>AdButler</AdSystem>
              <AdTitle>Test Ad</AdTitle>
              <Impression><![CDATA[https://example.com/impression]]></Impression>
              <Error><![CDATA[https://example.com/error]]></Error>
              <Creatives>
                <Creative>
                  <Linear skipoffset="00:00:05">
                    <Duration>00:00:30</Duration>
                    <MediaFiles>
                      <MediaFile type="video/mp4" width="1280" height="720" delivery="progressive" bitrate="1200">
                        <![CDATA[https://example.com/video.mp4]]>
                      </MediaFile>
                    </MediaFiles>
                    <TrackingEvents>
                      <Tracking event="start"><![CDATA[https://example.com/start]]></Tracking>
                      <Tracking event="firstQuartile"><![CDATA[https://example.com/q1]]></Tracking>
                      <Tracking event="midpoint"><![CDATA[https://example.com/mid]]></Tracking>
                      <Tracking event="thirdQuartile"><![CDATA[https://example.com/q3]]></Tracking>
                      <Tracking event="complete"><![CDATA[https://example.com/complete]]></Tracking>
                    </TrackingEvents>
                    <VideoClicks>
                      <ClickThrough><![CDATA[https://example.com/click-through]]></ClickThrough>
                      <ClickTracking><![CDATA[https://example.com/click-track]]></ClickTracking>
                    </VideoClicks>
                  </Linear>
                </Creative>
              </Creatives>
            </InLine>
          </Ad>
        </VAST>
        """.data(using: .utf8)!

        let parser = VASTParser()
        let response = try parser.parse(data: xml)

        XCTAssertEqual(response.version, "4.2")
        XCTAssertEqual(response.ads.count, 1)

        let ad = response.ads[0]
        XCTAssertEqual(ad.id, "ad-001")
        XCTAssertEqual(ad.sequence, 1)
        XCTAssertEqual(ad.adSystem, "AdButler")
        XCTAssertEqual(ad.adTitle, "Test Ad")
        XCTAssertEqual(ad.impressionUrls, ["https://example.com/impression"])
        XCTAssertEqual(ad.errorUrl, "https://example.com/error")
        XCTAssertFalse(ad.isWrapper)

        let linear = try XCTUnwrap(ad.linear)
        XCTAssertEqual(linear.duration, 30)
        XCTAssertEqual(linear.skipOffset, 5)
        XCTAssertEqual(linear.mediaFiles.count, 1)
        XCTAssertEqual(linear.clickThrough, "https://example.com/click-through")
        XCTAssertEqual(linear.clickTracking, ["https://example.com/click-track"])

        let media = linear.mediaFiles[0]
        XCTAssertEqual(media.url, "https://example.com/video.mp4")
        XCTAssertEqual(media.mimeType, "video/mp4")
        XCTAssertEqual(media.width, 1280)
        XCTAssertEqual(media.height, 720)
        XCTAssertEqual(media.bitrate, 1200)
        XCTAssertEqual(media.delivery, "progressive")

        XCTAssertEqual(linear.trackingEvents["start"]?.count, 1)
        XCTAssertEqual(linear.trackingEvents["firstQuartile"]?.count, 1)
        XCTAssertEqual(linear.trackingEvents["midpoint"]?.count, 1)
        XCTAssertEqual(linear.trackingEvents["thirdQuartile"]?.count, 1)
        XCTAssertEqual(linear.trackingEvents["complete"]?.count, 1)
    }

    func testParseVAST20() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <VAST version="2.0">
          <Ad id="v2-ad">
            <InLine>
              <AdSystem>LegacyAdServer</AdSystem>
              <AdTitle>VAST 2.0 Ad</AdTitle>
              <Impression><![CDATA[https://example.com/v2/impression]]></Impression>
              <Creatives>
                <Creative>
                  <Linear>
                    <Duration>00:00:15</Duration>
                    <MediaFiles>
                      <MediaFile type="video/mp4" width="640" height="480" delivery="progressive">
                        <![CDATA[https://example.com/v2/video.mp4]]>
                      </MediaFile>
                    </MediaFiles>
                    <TrackingEvents>
                      <Tracking event="start"><![CDATA[https://example.com/v2/start]]></Tracking>
                      <Tracking event="complete"><![CDATA[https://example.com/v2/complete]]></Tracking>
                    </TrackingEvents>
                    <VideoClicks>
                      <ClickThrough><![CDATA[https://example.com/v2/click]]></ClickThrough>
                    </VideoClicks>
                  </Linear>
                </Creative>
              </Creatives>
            </InLine>
          </Ad>
        </VAST>
        """.data(using: .utf8)!

        let parser = VASTParser()
        let response = try parser.parse(data: xml)

        XCTAssertEqual(response.version, "2.0")
        XCTAssertEqual(response.ads.count, 1)

        let ad = response.ads[0]
        XCTAssertEqual(ad.id, "v2-ad")
        XCTAssertNil(ad.linear?.skipOffset) // VAST 2.0 ad without skipoffset

        let linear = try XCTUnwrap(ad.linear)
        XCTAssertEqual(linear.duration, 15)
        XCTAssertEqual(linear.mediaFiles.count, 1)
        XCTAssertEqual(linear.mediaFiles[0].width, 640)
        XCTAssertEqual(linear.mediaFiles[0].height, 480)
    }

    func testParseWrapper() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <VAST version="4.2">
          <Ad id="wrapper-ad">
            <Wrapper>
              <AdSystem>Wrapper System</AdSystem>
              <Impression><![CDATA[https://wrapper.com/impression]]></Impression>
              <VASTAdTagURI><![CDATA[https://adserver.com/vast/inline.xml]]></VASTAdTagURI>
            </Wrapper>
          </Ad>
        </VAST>
        """.data(using: .utf8)!

        let parser = VASTParser()
        let response = try parser.parse(data: xml)

        let ad = response.ads[0]
        XCTAssertTrue(ad.isWrapper)
        XCTAssertEqual(ad.wrapperUrl, "https://adserver.com/vast/inline.xml")
        XCTAssertEqual(ad.impressionUrls, ["https://wrapper.com/impression"])
    }

    func testParseCompanionAds() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <VAST version="4.2">
          <Ad id="comp-ad">
            <InLine>
              <AdSystem>AdButler</AdSystem>
              <Impression><![CDATA[https://example.com/imp]]></Impression>
              <Creatives>
                <Creative>
                  <Linear>
                    <Duration>00:00:10</Duration>
                    <MediaFiles>
                      <MediaFile type="video/mp4" width="640" height="360" delivery="progressive">
                        <![CDATA[https://example.com/v.mp4]]>
                      </MediaFile>
                    </MediaFiles>
                  </Linear>
                </Creative>
                <Creative>
                  <CompanionAds>
                    <Companion width="300" height="250">
                      <StaticResource creativeType="image/png"><![CDATA[https://example.com/companion.png]]></StaticResource>
                      <CompanionClickThrough><![CDATA[https://example.com/comp-click]]></CompanionClickThrough>
                    </Companion>
                    <Companion width="728" height="90">
                      <HTMLResource><![CDATA[<div>HTML Companion</div>]]></HTMLResource>
                    </Companion>
                  </CompanionAds>
                </Creative>
              </Creatives>
            </InLine>
          </Ad>
        </VAST>
        """.data(using: .utf8)!

        let parser = VASTParser()
        let response = try parser.parse(data: xml)

        let ad = response.ads[0]
        XCTAssertEqual(ad.companions.count, 2)

        let static300 = ad.companions[0]
        XCTAssertEqual(static300.width, 300)
        XCTAssertEqual(static300.height, 250)
        XCTAssertEqual(static300.resourceType, "static")
        XCTAssertEqual(static300.content, "https://example.com/companion.png")
        XCTAssertEqual(static300.clickThrough, "https://example.com/comp-click")

        let html728 = ad.companions[1]
        XCTAssertEqual(html728.width, 728)
        XCTAssertEqual(html728.height, 90)
        XCTAssertEqual(html728.resourceType, "html")
        XCTAssertEqual(html728.content, "<div>HTML Companion</div>")
    }
}
