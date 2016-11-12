//
//  PlacementResponseOperation.swift
//  AdButler
//
//  Created by Ryuichi Saito on 11/11/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

class PlacementResponseOperation: AsynchronousOperation {
    let _responseCollector: ResponseCollector
    
    init(responseCollector: ResponseCollector) {
        _responseCollector = responseCollector
    }
    
    override func main() {
        let responses = _responseCollector.responses
        var placements = [Placement]()
        for response in responses {
            switch response {
            case .success(let status, let eachPlacements):
                placements.append(contentsOf: eachPlacements)
            default:
                ()
            }
        }
        let status: ResponseStatus = placements.isEmpty ? .noAds : .success
        _responseCollector.complete(.success(status, placements))
        finish()
    }
}
