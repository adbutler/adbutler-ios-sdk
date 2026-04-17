import Foundation
import UIKit

/// A request for an ad from AdButler.
/// Use the builder-style methods to add targeting parameters.
public struct AdRequest: Sendable {
    /// The zone ID to request an ad from.
    public let zoneId: Int

    /// Optional keywords for targeting.
    public var keywords: [String]?

    /// Expected ad size (width x height).
    public var width: Int?
    public var height: Int?

    /// Data key targeting key-value pairs.
    public var dataKeyTargeting: [String: String]?

    /// Referrer URL for contextual targeting.
    public var referrer: String?

    /// Page ID for unique delivery across zones.
    public var pageId: Int?

    /// Place counter for unique delivery.
    public var place: Int?

    /// Create an ad request for the given zone.
    public init(zoneId: Int) {
        self.zoneId = zoneId
    }

    /// Add keywords for targeting.
    public func keywords(_ keywords: [String]) -> AdRequest {
        var copy = self
        copy.keywords = keywords
        return copy
    }

    /// Set the expected ad size.
    public func size(width: Int, height: Int) -> AdRequest {
        var copy = self
        copy.width = width
        copy.height = height
        return copy
    }

    /// Add data key targeting.
    public func dataKeyTargeting(_ targeting: [String: String]) -> AdRequest {
        var copy = self
        copy.dataKeyTargeting = targeting
        return copy
    }

    /// Set the referrer URL.
    public func referrer(_ url: String) -> AdRequest {
        var copy = self
        copy.referrer = url
        return copy
    }

    /// Set page ID and place for unique delivery.
    public func uniqueDelivery(pageId: Int, place: Int) -> AdRequest {
        var copy = self
        copy.pageId = pageId
        copy.place = place
        return copy
    }

    /// Build the URL for the ad serve request.
    internal func buildUrl(accountId: Int, baseUrl: String) -> URL? {
        var path = "\(baseUrl)/adserve/;ID=\(accountId);setID=\(zoneId);type=json"

        if let kw = keywords, !kw.isEmpty {
            let joined = kw.joined(separator: ",")
            path += ";kw=\(joined)"
        }

        if let w = width, let h = height {
            path += ";size=\(w)x\(h)"
        }

        if let pid = pageId {
            path += ";pid=\(pid)"
        }

        if let p = place {
            path += ";place=\(p)"
        }

        guard var components = URLComponents(string: path) else { return nil }
        var queryItems: [URLQueryItem] = []

        let screen = UIScreen.main
        queryItems.append(URLQueryItem(name: "sw", value: "\(Int(screen.bounds.width))"))
        queryItems.append(URLQueryItem(name: "sh", value: "\(Int(screen.bounds.height))"))
        queryItems.append(URLQueryItem(name: "spr", value: "\(Int(screen.scale))"))

        if let ref = referrer {
            queryItems.append(URLQueryItem(name: "referrer", value: ref))
        }

        if let dkt = dataKeyTargeting, !dkt.isEmpty {
            if let json = try? JSONSerialization.data(withJSONObject: dkt),
               let str = String(data: json, encoding: .utf8) {
                queryItems.append(URLQueryItem(name: "_abdk_json", value: str))
            }
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        return components.url
    }
}
