import Foundation

/// Parsed VAST response (supports VAST 2.0 and 4.2).
public struct VASTResponse {
    /// VAST version detected ("2.0", "3.0", "4.0", "4.2", etc.)
    public let version: String

    /// Array of ads in the response.
    public let ads: [VASTAd]
}

/// A single VAST ad.
public struct VASTAd {
    /// Ad identifier.
    public let id: String?

    /// Sequence number for ad pods.
    public let sequence: Int?

    /// Ad system name (e.g., "AdButler").
    public let adSystem: String?

    /// Ad title.
    public let adTitle: String?

    /// Impression tracking URLs (fire when ad starts).
    public let impressionUrls: [String]

    /// Error tracking URL (fire on playback error).
    public let errorUrl: String?

    /// Linear (video) creative.
    public let linear: VASTLinear?

    /// Companion ads.
    public let companions: [VASTCompanion]

    /// Whether this is a wrapper (redirect to another VAST URL).
    public let isWrapper: Bool

    /// Wrapper VAST URL (if isWrapper is true).
    public let wrapperUrl: String?
}

/// Linear (video) creative.
public struct VASTLinear {
    /// Video duration in seconds.
    public let duration: TimeInterval

    /// Skip offset in seconds (nil = not skippable).
    public let skipOffset: TimeInterval?

    /// Available media files.
    public let mediaFiles: [VASTMediaFile]

    /// Tracking events: event name → [URLs].
    public let trackingEvents: [String: [String]]

    /// Click-through destination URL.
    public let clickThrough: String?

    /// Click tracking URLs.
    public let clickTracking: [String]
}

/// A single media file option.
public struct VASTMediaFile {
    /// Media file URL.
    public let url: String

    /// MIME type (e.g., "video/mp4").
    public let mimeType: String

    /// Video width.
    public let width: Int

    /// Video height.
    public let height: Int

    /// Bitrate in kbps (nil if not specified).
    public let bitrate: Int?

    /// Delivery method.
    public let delivery: String

    /// Video codec.
    public let codec: String?
}

/// Companion ad.
public struct VASTCompanion {
    /// Companion width.
    public let width: Int

    /// Companion height.
    public let height: Int

    /// Resource type: "static", "iframe", or "html".
    public let resourceType: String

    /// Resource content (image URL, iframe URL, or HTML string).
    public let content: String

    /// Click-through URL.
    public let clickThrough: String?

    /// Tracking pixels for the companion.
    public let trackingUrls: [String]
}

/// VAST quartile events.
public enum VASTQuartile: String, CaseIterable {
    case start = "start"
    case firstQuartile = "firstQuartile"
    case midpoint = "midpoint"
    case thirdQuartile = "thirdQuartile"
    case complete = "complete"
}
