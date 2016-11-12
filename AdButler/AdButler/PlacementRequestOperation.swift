//
//  PlacementRequestOperation.swift
//  AdButler
//
//  Created by Ryuichi Saito on 11/11/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

class PlacementRequestOperation: AsynchronousOperation {
    private let _baseUrl: String
    private let _config: PlacementRequestConfig
    private let _complete: (Response) -> Void
    
    private var _task: URLSessionDataTask?
    
    init(baseUrl: String, config: PlacementRequestConfig, completionHandler: @escaping (Response) -> Void) {
        _baseUrl = baseUrl
        _config = config
        _complete = completionHandler
    }
    
    private var session: URLSession = {
        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.httpAdditionalHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        return URLSession(configuration: sessionConfig)
    }()
    
    
    override func main() {
        guard let request = _config.buildRequest(with: _baseUrl) else {
            return
        }
        _task = session.dataTask(with: request) { [unowned self] (data, response, error) in
            if let error = error {
                self._complete(.requestError(error))
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
                    self._complete(.success(status, placements))
                } else {
                    self._complete(.invalidJson(String(data: data, encoding: .utf8)))
                }
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode
                var responseBody: String? = nil
                if let data = data {
                    responseBody = String(data: data, encoding: .utf8)
                }
                self._complete(.badRequest(statusCode, responseBody))
            }
            self.finish()
        }
        _task?.resume()
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
