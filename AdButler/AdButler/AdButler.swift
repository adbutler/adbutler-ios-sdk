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
    
    public func requestPlacement(with config: PlacementRequestConfig, completionHandler: @escaping () -> Void) {
        let urlString = "\(baseUrl)/\(config.queryString);type=json"
        guard let url = URL(string: urlString) else {
            completionHandler() // TODO: error handling
            return
        }
        let request = URLRequest(url: url)
        
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.httpAdditionalHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        let session = URLSession(configuration: sessionConfig)
        let task = session.dataTask(with: request) { (data, response, error) in
            if let _ = error {
                completionHandler() // TODO: error handling
            } else if let httpResponse = response as? HTTPURLResponse, let data = data, httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) {
                    print(json)
                }
            } else {
                completionHandler() // TODO: error handling
            }
        }
        task.resume()
    }
}
