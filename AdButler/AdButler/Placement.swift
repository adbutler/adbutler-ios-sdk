//
//  Placement.swift
//  AdButler
//
//  Created by Ryuichi Saito on 11/9/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

@objc public class Placement: NSObject {
    public let bannerId: Int
    public let redirectUrl: String?
    public let imageUrl: String?
    public let width: Int
    public let height: Int
    public let altText: String
    public let target: String
    public let trackingPixel: String?
    public let accupixelUrl: String?
    public let refreshUrl: String?
    public let refreshTime: String?
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
