//
//  Placement.swift
//  AdButler
//
//  Created by Ryuichi Saito on 11/9/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

/// Models the `Placement` with all its properties.
@objc public class Placement: NSObject {
    /// The unique ID of the banner returned.
    public let bannerId: Int
    /// A pass-through click redirect URL.
    public let redirectUrl: String?
    /// The image banner URL.
    public let imageUrl: String?
    /// The width of this placement.
    public let width: Int
    /// The height of this placement.
    public let height: Int
    /// Alternate text for screen readers on the web.
    public let altText: String
    /// An HTML target attribute.
    public let target: String
    /// An optional user-specified tracking pixel URL.
    public let trackingPixel: String?
    /// Used to record an impression for this request.
    public let accupixelUrl: String?
    /// Contains a zone URL to request a new ad.
    public let refreshUrl: String?
    /// The user-specified delay between refresh URL requests.
    public let refreshTime: String?
    /// The HTML markup of an ad request.
    public let body: String?
    
    public init(bannerId: Int, redirectUrl: String? = nil, imageUrl: String? = nil, width: Int, height: Int, altText: String, target: String, trackingPixel: String? = nil, accupixelUrl: String? = nil, refreshUrl: String? = nil, refreshTime: String? = nil, body: String? = nil) {
        self.bannerId = bannerId
        self.redirectUrl = redirectUrl
        self.imageUrl = imageUrl
        self.width = width
        self.height = height
        self.altText = altText
        self.target = target
        self.trackingPixel = trackingPixel
        self.accupixelUrl = accupixelUrl
        self.refreshUrl = refreshUrl
        self.refreshTime = refreshTime
        self.body = body
    }
}

public extension Placement {
    convenience init?(from jsonDictionary: [String: String]) {
        guard let bannerIdString = jsonDictionary["banner_id"],
            let bannerId = Int(bannerIdString),
            let widthString = jsonDictionary["width"],
            let width = Int(widthString),
            let heightString = jsonDictionary["height"],
            let height = Int(heightString),
            let altText = jsonDictionary["alt_text"],
            let target = jsonDictionary["target"] else {
                return nil
        }
        
        let mapBlankToNil: (String?) -> String? = { str in
            if let str = str, !str.isEmpty {
                return str
            } else {
                return nil
            }
        }
        let redirectUrl = mapBlankToNil(jsonDictionary["redirect_url"])
        let imageUrl = mapBlankToNil(jsonDictionary["image_url"])
        let trackingPixel = mapBlankToNil(jsonDictionary["tracking_pixel"])
        let accupixelUrl = mapBlankToNil(jsonDictionary["accupixel_url"])
        let refreshUrl = mapBlankToNil(jsonDictionary["refresh_url"])
        let refreshTime = mapBlankToNil(jsonDictionary["refresh_time"])
        let body = mapBlankToNil(jsonDictionary["body"])
        
        self.init(bannerId: bannerId, redirectUrl: redirectUrl, imageUrl: imageUrl, width: width, height: height, altText: altText, target: target, trackingPixel: trackingPixel, accupixelUrl: accupixelUrl, refreshUrl: refreshUrl, refreshTime: refreshTime, body: body)
    }
}
