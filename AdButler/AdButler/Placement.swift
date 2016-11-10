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
