//
//  AdButler.swift
//  AdButler
//
//  Created by Ryuichi Saito on 11/8/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

fileprivate let baseUrl = "https://servedbyadbutler.com/adserve"

@objc public class AdButler: NSObject {
    public override init() {
        super.init()
    }
    
    public static func requestPlacements(with configs: [PlacementRequestConfig], completionHandler: @escaping (Response) -> Void) {
        let requestManager = RequestManager(baseUrl: baseUrl, configs: configs, completionHandler: completionHandler)
        requestManager.request()
    }
    
    @objc public static func requestPlacements(with configs: [PlacementRequestConfig], success: @escaping (String, [Placement]) -> Void, failure: @escaping (NSNumber?, String?, Error?) -> Void) {
        requestPlacements(with: configs) { $0.objcCallbacks(success: success, failure: failure) }
    }
    
    public static func requestPlacement(with config: PlacementRequestConfig, completionHandler: @escaping (Response) -> Void) {
        let requestManager = RequestManager(baseUrl: baseUrl, config: config, completionHandler: completionHandler)
        requestManager.request()
    }
    
    @objc public static func requestPlacement(with config: PlacementRequestConfig, success: @escaping (String, [Placement]) -> Void, failure: @escaping (NSNumber?, String?, Error?) -> Void) {
        requestPlacement(with: config) { $0.objcCallbacks(success: success, failure: failure) }
    }
    
    @objc public static func requestPixel(with url: URL) {
        let session = Session().urlSession
        let task = session.dataTask(with: url) { (_, _, error) in
            if error != nil {
                print("Error requeseting a pixel with url \(url.absoluteString)")
            }
        }
        task.resume()
    }
}

fileprivate extension Response {
    func objcCallbacks(success: @escaping (String, [Placement]) -> Void, failure: @escaping (NSNumber?, String?, Error?) -> Void) {
        switch self {
        case .success(let status, let placements):
            success(status.rawValue, placements)
        case .badRequest(let statusCode, let responseBody):
            var statusCodeNumber: NSNumber? = nil
            if let statusCode = statusCode {
                statusCodeNumber = statusCode as NSNumber
            }
            failure(statusCodeNumber, responseBody, nil)
        case .invalidJson(let responseBody):
            failure(nil, responseBody, nil)
        case .requestError(let error):
            failure(nil, nil, error)
        }
    }
}
