//
//  PlacementRequestConfig.swift
//  AdButler
//
//  Created by Ryuichi Saito on 11/8/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

/// Configures the parameters used in requesting a `Placement`.
@objc public class PlacementRequestConfig: NSObject {
    /// The account ID for this request.
    public var accountId: Int
    /// The publisher zone ID to select advertisements from.
    public var zoneId: Int
    /// The width of the publisher zone.
    public var width: Int
    /// The height of the publisher zone.
    public var height: Int
    /// A comma delimited list of keywords.
    public var keywords: [String]
    /// A pass-through click URL.
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
    var queryString: String {
        var query = ";ID=\(accountId);size=\(width)x\(height);setID=\(zoneId)"
        if !keywords.isEmpty {
            let keywordsString = keywords.joined(separator: ",")
            query += ";kw=\(keywordsString)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        }
        if let click = click {
            query += ";click=\(click)"
        }
        return query
    }
}
