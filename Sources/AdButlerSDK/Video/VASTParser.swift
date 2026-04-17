import Foundation

/// Parses VAST 2.0 and 4.2 XML into a unified VASTResponse model.
/// Auto-detects the VAST version from the root element's version attribute.
internal final class VASTParser: NSObject, XMLParserDelegate {
    private var result: VASTResponse?
    private var parseError: Error?

    // Parsing state
    private var version: String = ""
    private var ads: [VASTAd] = []

    // Current ad state
    private var currentAdId: String?
    private var currentAdSequence: Int?
    private var currentAdSystem: String?
    private var currentAdTitle: String?
    private var currentImpressionUrls: [String] = []
    private var currentErrorUrl: String?
    private var currentIsWrapper = false
    private var currentWrapperUrl: String?

    // Linear state
    private var currentLinear: VASTLinear?
    private var currentDuration: TimeInterval = 0
    private var currentSkipOffset: TimeInterval?
    private var currentMediaFiles: [VASTMediaFile] = []
    private var currentTrackingEvents: [String: [String]] = [:]
    private var currentClickThrough: String?
    private var currentClickTracking: [String] = []

    // Media file attributes
    private var currentMediaType: String?
    private var currentMediaWidth: Int = 0
    private var currentMediaHeight: Int = 0
    private var currentMediaBitrate: Int?
    private var currentMediaDelivery: String = "progressive"
    private var currentMediaCodec: String?

    // Companion state
    private var currentCompanions: [VASTCompanion] = []
    private var currentCompanionWidth: Int = 0
    private var currentCompanionHeight: Int = 0
    private var currentCompanionResourceType: String?
    private var currentCompanionContent: String?
    private var currentCompanionClickThrough: String?
    private var currentCompanionTrackingUrls: [String] = []

    // Tracking event attribute
    private var currentTrackingEvent: String?

    // Element stack and character buffer
    private var elementStack: [String] = []
    private var characterBuffer = ""

    /// Parse VAST XML data into a VASTResponse.
    func parse(data: Data) throws -> VASTResponse {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        if let error = parseError {
            throw AdButlerError.vastParseError(message: error.localizedDescription)
        }

        guard let result = result else {
            throw AdButlerError.vastParseError(message: "Failed to parse VAST XML")
        }

        return result
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String] = [:]) {
        elementStack.append(elementName)
        characterBuffer = ""

        switch elementName {
        case "VAST":
            version = attributes["version"] ?? "2.0"

        case "Ad":
            currentAdId = attributes["id"]
            currentAdSequence = attributes["sequence"].flatMap(Int.init)
            currentAdSystem = nil
            currentAdTitle = nil
            currentImpressionUrls = []
            currentErrorUrl = nil
            currentLinear = nil
            currentMediaFiles = []
            currentTrackingEvents = [:]
            currentClickThrough = nil
            currentClickTracking = []
            currentCompanions = []
            currentIsWrapper = false
            currentWrapperUrl = nil

        case "Wrapper":
            currentIsWrapper = true

        case "Linear":
            currentDuration = 0
            currentSkipOffset = nil
            currentMediaFiles = []
            currentTrackingEvents = [:]
            currentClickThrough = nil
            currentClickTracking = []

            if let skipStr = attributes["skipoffset"] {
                currentSkipOffset = parseTimeOffset(skipStr)
            }

        case "MediaFile":
            currentMediaType = attributes["type"] ?? "video/mp4"
            currentMediaWidth = Int(attributes["width"] ?? "0") ?? 0
            currentMediaHeight = Int(attributes["height"] ?? "0") ?? 0
            currentMediaBitrate = attributes["bitrate"].flatMap(Int.init)
            currentMediaDelivery = attributes["delivery"] ?? "progressive"
            currentMediaCodec = attributes["codec"]

        case "Tracking":
            currentTrackingEvent = attributes["event"]

        case "Companion":
            currentCompanionWidth = Int(attributes["width"] ?? "0") ?? 0
            currentCompanionHeight = Int(attributes["height"] ?? "0") ?? 0
            currentCompanionResourceType = nil
            currentCompanionContent = nil
            currentCompanionClickThrough = nil
            currentCompanionTrackingUrls = []

        case "StaticResource":
            currentCompanionResourceType = "static"
            // creativeType attribute gives us the MIME type
            _ = attributes["creativeType"]

        case "IFrameResource":
            currentCompanionResourceType = "iframe"

        case "HTMLResource":
            currentCompanionResourceType = "html"

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        characterBuffer += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if let str = String(data: CDATABlock, encoding: .utf8) {
            characterBuffer += str
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName: String?) {
        let text = characterBuffer.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "VAST":
            result = VASTResponse(version: version, ads: ads)

        case "Ad":
            let ad = VASTAd(
                id: currentAdId,
                sequence: currentAdSequence,
                adSystem: currentAdSystem,
                adTitle: currentAdTitle,
                impressionUrls: currentImpressionUrls,
                errorUrl: currentErrorUrl,
                linear: currentLinear,
                companions: currentCompanions,
                isWrapper: currentIsWrapper,
                wrapperUrl: currentWrapperUrl
            )
            ads.append(ad)

        case "AdSystem":
            currentAdSystem = text

        case "AdTitle":
            currentAdTitle = text

        case "Impression":
            if !text.isEmpty { currentImpressionUrls.append(text) }

        case "Error":
            currentErrorUrl = text

        case "Duration":
            currentDuration = parseTimeOffset(text) ?? 0

        case "MediaFile":
            if !text.isEmpty {
                let mediaFile = VASTMediaFile(
                    url: text,
                    mimeType: currentMediaType ?? "video/mp4",
                    width: currentMediaWidth,
                    height: currentMediaHeight,
                    bitrate: currentMediaBitrate,
                    delivery: currentMediaDelivery,
                    codec: currentMediaCodec
                )
                currentMediaFiles.append(mediaFile)
            }

        case "Tracking":
            if let event = currentTrackingEvent, !text.isEmpty {
                currentTrackingEvents[event, default: []].append(text)
            }

        case "ClickThrough":
            if isInCompanion() {
                currentCompanionClickThrough = text
            } else {
                currentClickThrough = text
            }

        case "CompanionClickThrough":
            currentCompanionClickThrough = text

        case "ClickTracking":
            if !text.isEmpty { currentClickTracking.append(text) }

        case "Linear":
            currentLinear = VASTLinear(
                duration: currentDuration,
                skipOffset: currentSkipOffset,
                mediaFiles: currentMediaFiles,
                trackingEvents: currentTrackingEvents,
                clickThrough: currentClickThrough,
                clickTracking: currentClickTracking
            )

        case "StaticResource", "IFrameResource", "HTMLResource":
            currentCompanionContent = text

        case "Companion":
            if let resourceType = currentCompanionResourceType,
               let content = currentCompanionContent {
                let companion = VASTCompanion(
                    width: currentCompanionWidth,
                    height: currentCompanionHeight,
                    resourceType: resourceType,
                    content: content,
                    clickThrough: currentCompanionClickThrough,
                    trackingUrls: currentCompanionTrackingUrls
                )
                currentCompanions.append(companion)
            }

        case "VASTAdTagURI":
            currentWrapperUrl = text

        default:
            break
        }

        elementStack.removeLast()
        characterBuffer = ""
    }

    func parser(_ parser: XMLParser, parseErrorOccurred error: Error) {
        parseError = error
    }

    // MARK: - Helpers

    private func isInCompanion() -> Bool {
        elementStack.contains("Companion")
    }

    /// Parse a VAST time offset string (HH:MM:SS or HH:MM:SS.mmm or percentage).
    private func parseTimeOffset(_ str: String) -> TimeInterval? {
        let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)

        // Percentage (e.g., "50%")
        if trimmed.hasSuffix("%") {
            // Percentage offsets are relative to duration — not supported standalone
            return nil
        }

        // HH:MM:SS or HH:MM:SS.mmm
        let parts = trimmed.split(separator: ":").map(String.init)
        guard parts.count == 3 else { return nil }

        let hours = Double(parts[0]) ?? 0
        let minutes = Double(parts[1]) ?? 0
        let seconds = Double(parts[2]) ?? 0

        return hours * 3600 + minutes * 60 + seconds
    }
}
