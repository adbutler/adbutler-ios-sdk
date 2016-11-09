//
//  PlacementRequestConfig.swift
//  AdButler
//
//  Created by Ryuichi Saito on 11/8/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

public class PlacementRequestConfig {
    public var accountId: Int
    public var zoneId: Int
    public var width: Int
    public var height: Int
    public var keywords: [String]
    public var click: String?
    
    public init(accountId: Int, zoneId: Int, width: Int, height: Int, keywords: [String] = [], click: String? = nil) {
        self.accountId = accountId
        self.zoneId = zoneId
        self.width = width
        self.height = height
        self.keywords = keywords
        self.click = click
    }
}

public extension PlacementRequestConfig {
    public var queryString: String {
        var query = ";ID=\(accountId);size=\(width)x\(height);setID=\(zoneId)"
        if !keywords.isEmpty {
            let keywordsString = keywords.joined(separator: ",")
            query += ";kw=\(keywordsString)"
        }
        if let click = click {
            query += ";click=\(click)"
        }
        return query
    }
}
