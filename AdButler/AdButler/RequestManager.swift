//
//  RequestManager.swift
//  AdButler
//
//  Created by Ryuichi Saito on 11/11/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

class RequestManager {
    private let _baseUrl: String
    private let _configs: [PlacementRequestConfig]
    fileprivate let _complete: (Response) -> Void
    
    fileprivate var _responses: [Response]
    
    init(baseUrl: String, configs: [PlacementRequestConfig], completionHandler: @escaping (Response) -> Void) {
        _baseUrl = baseUrl
        _configs = configs
        _complete = completionHandler
        _responses = []
    }
    
    convenience init(baseUrl: String, config: PlacementRequestConfig, completionHandler: @escaping (Response) -> Void) {
        self.init(baseUrl: baseUrl, configs: [config], completionHandler: completionHandler)
    }
    
    func request() {
        var operations = [Operation]()
        let responseOperation = PlacementResponseOperation(responseCollector: self)
        for config in _configs {
            let requestOperation = PlacementRequestOperation(baseUrl: _baseUrl, config: config, completionHandler: { [unowned self] (response) in
                self._responses.append(response)
            })
            responseOperation.addDependency(requestOperation)
            operations.append(requestOperation)
        }
        operations.append(responseOperation)
        OperationQueue.main.addOperations(operations, waitUntilFinished: false)
    }
}

extension RequestManager: ResponseCollector {
    var responses: [Response] {
        return _responses
    }
    
    var complete: (Response) -> Void {
        return _complete
    }
}
