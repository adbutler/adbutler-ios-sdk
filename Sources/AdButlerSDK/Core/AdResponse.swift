import Foundation

/// Parsed response from the AdButler ad serving endpoint.
public struct AdResponse: Sendable {
    /// The ad item (banner) ID.
    public let bannerId: Int

    /// Direct image URL for display ads.
    public let imageUrl: String?

    /// Click tracking redirect URL.
    public let redirectUrl: String?

    /// Impression tracking pixel URL. Fire before rendering.
    public let accupixelUrl: String?

    /// Viewability callback — fire when ad renders on screen.
    public let eligibleUrl: String?

    /// Viewability callback — fire when 50%+ visible for 1+ second.
    public let viewableUrl: String?

    /// Raw HTML body for rich media, custom HTML, or native ads.
    public let body: String?

    /// Ad width in pixels.
    public let width: Int

    /// Ad height in pixels.
    public let height: Int

    /// Third-party tracking pixel URL.
    public let trackingPixel: String?

    /// URL for auto-refresh.
    public let refreshUrl: String?

    /// Auto-refresh interval in seconds.
    public let refreshTime: Int?

    /// Alt text for image ads.
    public let altText: String?

    /// Link target (_blank, _self, etc.).
    public let target: String?

    /// Whether the ad has HTML body content (rich media / native).
    public var isHtmlAd: Bool {
        body != nil && !(body?.isEmpty ?? true)
    }

    /// Whether the ad has an image URL (display ad).
    public var isImageAd: Bool {
        imageUrl != nil && !(imageUrl?.isEmpty ?? true) && !isHtmlAd
    }
}

// MARK: - JSON Parsing

extension AdResponse {
    /// Parse an AdResponse from a raw JSON dictionary (single placement).
    internal static func parse(from json: [String: Any]) throws -> AdResponse {
        guard let bannerId = json["banner_id"] as? Int else {
            throw AdButlerError.parseError(message: "Missing banner_id in ad response")
        }

        return AdResponse(
            bannerId: bannerId,
            imageUrl: json["image_url"] as? String,
            redirectUrl: json["redirect_url"] as? String,
            accupixelUrl: json["accupixel_url"] as? String,
            eligibleUrl: json["eligible_url"] as? String,
            viewableUrl: json["viewable_url"] as? String,
            body: json["body"] as? String,
            width: json["width"] as? Int ?? 0,
            height: json["height"] as? Int ?? 0,
            trackingPixel: json["tracking_pixel"] as? String,
            refreshUrl: json["refresh_url"] as? String,
            refreshTime: json["refresh_time"] as? Int,
            altText: json["alt_text"] as? String,
            target: json["target"] as? String
        )
    }

    /// Parse the top-level adserve response and extract the first placement.
    internal static func parseAdServeResponse(data: Data) throws -> AdResponse {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AdButlerError.parseError(message: "Invalid JSON in ad response")
        }

        let status = json["status"] as? String ?? ""
        guard status == "SUCCESS" else {
            throw AdButlerError.noAdAvailable
        }

        guard let placements = json["placements"] as? [String: Any] else {
            throw AdButlerError.parseError(message: "Missing placements in ad response")
        }

        // Get the first placement (key is like "placement_1")
        guard let firstKey = placements.keys.sorted().first,
              let placementData = placements[firstKey] else {
            throw AdButlerError.noAdAvailable
        }

        // Placement can be a dictionary (single ad) or array
        if let adDict = placementData as? [String: Any] {
            return try parse(from: adDict)
        } else if let adArray = placementData as? [[String: Any]], let first = adArray.first {
            return try parse(from: first)
        }

        throw AdButlerError.noAdAvailable
    }
}
