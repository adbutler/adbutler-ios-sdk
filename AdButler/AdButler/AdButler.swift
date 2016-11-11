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
    
    private static var session: URLSession = {
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.httpAdditionalHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        return URLSession(configuration: sessionConfig)
    }()
    
    public static func requestPlacement(with config: PlacementRequestConfig, completionHandler: @escaping (Response) -> Void) {
        guard let request = config.buildRequest(with: baseUrl) else {
            return
        }
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completionHandler(.requestError(error))
            } else if let httpResponse = response as? HTTPURLResponse, let data = data, httpResponse.statusCode == 200 {
                if let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                    let statusString = json["status"] as? String,
                    let status = ResponseStatus(rawValue: statusString),
                    let placementDictionary = json["placements"] as? [String: [String: String]] {
                    var placements = [Placement]()
                    for (_, v) in placementDictionary {
                        if let placement = Placement(from: v) {
                            placements.append(placement)
                        }
                    }
                    completionHandler(.success(status, placements))
                } else {
                    completionHandler(.invalidJson(String(data: data, encoding: .utf8)))
                }
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode
                var responseBody: String? = nil
                if let data = data {
                    responseBody = String(data: data, encoding: .utf8)
                }
                completionHandler(.badRequest(statusCode, responseBody))
            }
        }
        task.resume()
    }
    
    @objc public static func requestPlacement(with config: PlacementRequestConfig, success: @escaping (String, [Placement]) -> Void, failure: @escaping (NSNumber?, String?, Error?) -> Void) {
        requestPlacement(with: config) { response in
            switch response {
            case .success(let status, let placements):
                success(status.rawValue, placements)
            case .badRequest(let statusCode, let responseBody):
                var statusCodeNumber: NSNumber? = nil
                if let statusCode = statusCode {
                    statusCodeNumber = statusCode as? NSNumber
                }
                failure(statusCodeNumber, responseBody, nil)
            case .invalidJson(let responseBody):
                failure(nil, responseBody, nil)
            case .requestError(let error):
                failure(nil, nil, error)
            }
        }
    }
}

fileprivate extension PlacementRequestConfig {
    func buildRequest(with baseUrl: String) -> URLRequest? {
        let urlString = "\(baseUrl)/\(queryString);type=json"
        guard let url = URL(string: urlString) else {
            return nil
        }
        return URLRequest(url: url)
    }
}
