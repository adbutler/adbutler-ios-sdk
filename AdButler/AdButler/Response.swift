//
//  Response.swift
//  AdButler
//
//  Created by Ryuichi Saito on 11/9/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

public enum ResponseStatus: String {
    case success = "SUCCESS"
    case noAds = "NO_ADS"
}

public enum Response {
    case success(ResponseStatus, [Placement])
    case badRequest(Int?, String?)
    case invalidJson(String?)
    case requestError(Error)
}
