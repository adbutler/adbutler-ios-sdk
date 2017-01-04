//
//  Placement+Records.swift
//  AdButler
//
//  Created by Ryuichi Saito on 11/20/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

public extension Placement {
    /// Sends request to record impression for this `Placement`.
    public func recordImpression() {
        if let accupixelUrl = self.accupixelUrl.flatMap({ URL(string: $0) }) {
            AdButler.requestPixel(with: accupixelUrl)
        }
        if let trackingPixel = self.trackingPixel.flatMap({ URL(string: $0) }) {
            AdButler.requestPixel(with: trackingPixel)
        }
    }
    
    /// Sends request to record click for this `Placement`.
    public func recordClick() {
        if let redirectUrl = self.redirectUrl.flatMap({ URL(string: $0) }) {
            AdButler.requestPixel(with: redirectUrl)
        } else {
            print("Cannot construct a valid redirect URL.")
        }
    }
}
