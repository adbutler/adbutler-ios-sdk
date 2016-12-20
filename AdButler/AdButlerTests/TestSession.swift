//
//  TestSession.swift
//  AdButler
//
//  Created by Ryuichi Saito on 12/18/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

struct TestError : Error {
    
}

enum TestSession {
    case success([String: Any])
    case badRequest(Int)
    case invalidJson
    case requestError
}

extension TestSession {
    var session: URLSession {
        switch self {
        case .success(let placement):
            return SuccessSession(placement: placement)
        case .badRequest(let statusCode):
            return BadRequestSession(statusCode: statusCode)
        case .invalidJson:
            return InvalidJSONSession()
        case .requestError:
            return RequestErrorSession()
        }
    }
}

typealias TaskCompletion = (Data?, URLResponse?, Error?) -> Void

class SuccessSession : URLSession {
    private let _placement: [String: Any]
    
    init(placement: [String: Any]) {
        _placement = placement
    }
    
    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return SuccessSessionDataTask(url: url, placement: _placement, completion: completionHandler)
    }
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return SuccessSessionDataTask(url: request.url!, placement: _placement, completion: completionHandler)
    }
}

class SuccessSessionDataTask : URLSessionDataTask {
    private let _url: URL
    private let _placement: [String: Any]
    private let _completion: TaskCompletion
    
    init(url: URL, placement: [String: Any], completion: @escaping TaskCompletion) {
        _url = url
        _placement = placement
        _completion = completion
    }
    
    override func resume() {
        let dict: [String: Any] = [
            "status": "SUCCESS",
            "placements": ["placement_1": _placement]
        ]
        let json = try? JSONSerialization.data(withJSONObject: dict)
        let response = HTTPURLResponse(url: _url, statusCode: 200, httpVersion: nil, headerFields: nil)
        _completion(json, response, nil)
    }
}

class BadRequestSession : URLSession {
    private let _statusCode: Int
    
    init(statusCode: Int) {
        _statusCode = statusCode
    }
    
    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return BadRequestSessionDataTask(url: url, statusCode: _statusCode, completion: completionHandler)
    }
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return BadRequestSessionDataTask(url: request.url!, statusCode: _statusCode, completion: completionHandler)
    }
}

class BadRequestSessionDataTask : URLSessionDataTask {
    private let _url: URL
    private let _statusCode: Int
    private let _completion: TaskCompletion
    
    init(url: URL, statusCode: Int, completion: @escaping TaskCompletion) {
        _url = url
        _statusCode = statusCode
        _completion = completion
    }
    
    override func resume() {
        let badRequestData = "bad request".data(using: .utf8)
        let response = HTTPURLResponse(url: _url, statusCode: _statusCode, httpVersion: nil, headerFields: nil)
        _completion(badRequestData, response, nil)
    }
}

class InvalidJSONSession : URLSession {
    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return InvalidJSONSessionDataTask(url: url, completion: completionHandler)
    }
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return InvalidJSONSessionDataTask(url: request.url!, completion: completionHandler)
    }
}

class InvalidJSONSessionDataTask : URLSessionDataTask {
    private let _url: URL
    private let _completion: TaskCompletion
    
    init(url: URL, completion: @escaping TaskCompletion) {
        _url = url
        _completion = completion
    }
    
    override func resume() {
        let invalidJSONData = "invalid json".data(using: .utf8)
        let response = HTTPURLResponse(url: _url, statusCode: 200, httpVersion: nil, headerFields: nil)
        _completion(invalidJSONData, response, nil)
    }
}

class RequestErrorSession : URLSession {
    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return RequestErrorSessionDataTask(url: url, completion: completionHandler)
    }
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return RequestErrorSessionDataTask(url: request.url!, completion: completionHandler)
    }
}

class RequestErrorSessionDataTask : URLSessionDataTask {
    private let _url: URL
    private let _completion: TaskCompletion
    
    init(url: URL, completion: @escaping TaskCompletion) {
        _url = url
        _completion = completion
    }
    
    override func resume() {
        let response = HTTPURLResponse(url: _url, statusCode: 500, httpVersion: nil, headerFields: nil)
        _completion(nil, response, TestError())
    }
}
