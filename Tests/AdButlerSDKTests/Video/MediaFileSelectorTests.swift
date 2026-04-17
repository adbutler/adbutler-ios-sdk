import XCTest
@testable import AdButlerSDK

final class MediaFileSelectorTests: XCTestCase {
    let files: [VASTMediaFile] = [
        VASTMediaFile(url: "https://example.com/1080p.mp4", mimeType: "video/mp4", width: 1920, height: 1080, bitrate: 2000, delivery: "progressive", codec: "H.264"),
        VASTMediaFile(url: "https://example.com/720p.mp4", mimeType: "video/mp4", width: 1280, height: 720, bitrate: 1200, delivery: "progressive", codec: nil),
        VASTMediaFile(url: "https://example.com/360p.mp4", mimeType: "video/mp4", width: 640, height: 360, bitrate: 600, delivery: "progressive", codec: nil),
        VASTMediaFile(url: "https://example.com/720p.webm", mimeType: "video/webm", width: 1280, height: 720, bitrate: 1000, delivery: "progressive", codec: nil),
    ]

    func testSelectsBestFit() {
        let selected = MediaFileSelector.selectBest(from: files)
        XCTAssertNotNil(selected)
        // Should pick an mp4 (preferred) with best fit for screen
        XCTAssertEqual(selected?.mimeType, "video/mp4")
    }

    func testBitrateFilter() {
        let selected = MediaFileSelector.selectBest(from: files, maxBitrate: 800)
        XCTAssertNotNil(selected)
        // Should only pick the 360p (600kbps) since others exceed 800
        XCTAssertEqual(selected?.url, "https://example.com/360p.mp4")
    }

    func testEmptyFiles() {
        let selected = MediaFileSelector.selectBest(from: [])
        XCTAssertNil(selected)
    }

    func testUnsupportedMimeType() {
        let unsupported = [
            VASTMediaFile(url: "https://example.com/ad.flv", mimeType: "video/x-flv", width: 640, height: 480, bitrate: 800, delivery: "progressive", codec: nil),
        ]
        let selected = MediaFileSelector.selectBest(from: unsupported)
        // Falls back to any progressive file
        XCTAssertNotNil(selected)
    }

    func testPrefersMp4OverWebm() {
        let mixed = [
            VASTMediaFile(url: "https://example.com/720p.webm", mimeType: "video/webm", width: 1280, height: 720, bitrate: 1200, delivery: "progressive", codec: nil),
            VASTMediaFile(url: "https://example.com/720p.mp4", mimeType: "video/mp4", width: 1280, height: 720, bitrate: 1200, delivery: "progressive", codec: nil),
        ]
        let selected = MediaFileSelector.selectBest(from: mixed)
        XCTAssertEqual(selected?.mimeType, "video/mp4")
    }
}
