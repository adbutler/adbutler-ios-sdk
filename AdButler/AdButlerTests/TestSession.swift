//
//  TestSession.swift
//  AdButler
//
//  Created by Ryuichi Saito on 12/18/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

enum TestSession {
    case sample1
    case sample2
}

extension TestSession {
    var session: URLSession {
        switch self {
        case .sample1:
            return Sample1Session()
        default:
            return URLSession.shared
        }
    }
}

class Sample1Session : URLSession {
    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return Sample1DataTask(url: url, completion: completionHandler)
    }
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return Sample1DataTask(url: request.url!, completion: completionHandler)
    }
}

typealias TaskCompletion = (Data?, URLResponse?, Error?) -> Void

class Sample1DataTask : URLSessionDataTask {
    private let _url: URL
    private let _completion: TaskCompletion
    
    init(url: URL, completion: @escaping TaskCompletion) {
        _url = url
        _completion = completion
    }
    
    override func resume() {
        let dict: [String: Any] = [
            "status": "SUCCESS",
            "placements": [
                "placement_1": [
                    "banner_id": "519401954",
                    "redirect_url": "https://servedbyadbutler.com/redirect.spark?MID=153105&plid=543820&setID=214764&channelID=0&CID=0&banID=519401954&PID=0&textadID=0&tc=1&mt=1482121253469173&hc=fdc53f2a708e63ffd71bf224471433202cd31416&location=",
                    "image_url": "https://servedbyadbutler.com/default_banner.gif",
                    "width": "300",
                    "height": "250",
                    "alt_text": "",
                    "target": "_blank",
                    "tracking_pixel": "",
                    "accupixel_url": "https://servedbyadbutler.com/adserve.ibs/;ID=153105;size=1x1;type=pixel;setID=214764;plid=543820;BID=519401954;wt=1482121263;rnd=99929",
                    "refresh_url": "",
                    "refresh_time": "",
                    "body": ""
                ]
            ]
        ]
        let json = try? JSONSerialization.data(withJSONObject: dict)
        let response = HTTPURLResponse(url: _url, statusCode: 200, httpVersion: nil, headerFields: nil)
        _completion(json, response, nil)
    }
}
