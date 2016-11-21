//
//  Placement+Records.swift
//  AdButler
//
//  Created by Ryuichi Saito on 11/20/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

public extension Placement {
    public func recordImpression() {
        if let accupixelUrl = self.accupixelUrl.map({ URL(string: $0) }), let url = accupixelUrl {
            AdButler.requestPixel(with: url)
        } else if let trackingPixel = self.trackingPixel.map({ URL(string: $0) }), let url = trackingPixel {
            AdButler.requestPixel(with: url)
        } else {
            print("Cannot construct a valid impression URL.")
        }
    }
    
    public func recordClick() {
        if let redirectUrl = self.redirectUrl.map({ URL(string: $0) }), let url = redirectUrl {
            AdButler.requestPixel(with: url)
        } else {
            print("Cannot construct a valid redirect URL.")
        }
    }
}
