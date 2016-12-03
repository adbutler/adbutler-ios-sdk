//
//  ViewController.swift
//  Swift Sample
//
//  Created by Ryuichi Saito on 11/8/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import UIKit
import AdButler

class ViewController: UIViewController {
    @IBAction func requestPlacementTapped(_ sender: Any) {
        let config = PlacementRequestConfig(accountId: 153105, zoneId: 214764, width: 300, height: 250)
        AdButler.requestPlacement(with: config) { response in
            switch response {
            case .success(let status, let placements):
                print(status.rawValue)
                print(placements.map({ $0.debugString }))
            case .badRequest(let statusCode, let responseBody):
                print(statusCode ?? -1)
                print(responseBody ?? "<no body>")
            case .invalidJson(let responseBody):
                print(responseBody ?? "<no body>")
            case .requestError(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func requestPlacementsTapped(_ sender: Any) {
        let configs: [PlacementRequestConfig] = [
            PlacementRequestConfig(accountId: 153105, zoneId: 214764, width: 300, height: 250),
            PlacementRequestConfig(accountId: 153105, zoneId: 214764, width: 300, height: 250, keywords: ["sample2"]),
        ]
        AdButler.requestPlacements(with: configs) { response in
            switch response {
            case .success(let status, let placements):
                print(status.rawValue)
                print(placements.map({ $0.debugString }))
            case .badRequest(let statusCode, let responseBody):
                print(statusCode ?? -1)
                print(responseBody ?? "<no body>")
            case .invalidJson(let responseBody):
                print(responseBody ?? "<no body>")
            case .requestError(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func requestPixelTapped(_ sender: Any) {
        guard let url = URL(string: "https://servedbyadbutler.com/default_banner.gif") else {
            print("Failed in getting a url")
            return
        }
        AdButler.requestPixel(with: url)
    }
    
    @IBAction func recordImpressionTapped(_ sender: Any) {
        let placement = getSamplePlacement()
        placement.recordImpression()
    }
    
    @IBAction func recordClickTapped(_ sender: Any) {
        let placement = getSamplePlacement()
        placement.recordClick()
    }
    
    private func getSamplePlacement() -> Placement {
        return Placement(
            bannerId: 519407754,
            redirectUrl: "https://servedbyadbutler.com/redirect.spark?MID=153105&plid=550986&setID=214764&channelID=0&CID=0&banID=519407754&PID=0&textadID=0&tc=1&mt=1480778998606477&hc=534448fb7fb5835eaca37f949e61a363d8237324&location=",
            imageUrl: "http://servedbyadbutler.com/default_banner.gif",
            width: 300,
            height: 250,
            altText: "",
            target: "_blank",
            trackingPixel: "http://servedbyadbutler.com/default_banner.gif?foo=bar&demo=fakepixel",
            accupixelUrl: "https://servedbyadbutler.com/adserve.ibs/;ID=153105;size=1x1;type=pixel;setID=214764;plid=550986;BID=519407754;wt=1480779008;rnd=90858")
    }
}

extension Placement {
    var debugString: String {
        return "bannerId: \(bannerId), redirectUrl: \(redirectUrl), imageUrl: \(imageUrl), width: \(width), height: \(height), altText: \(altText), target: \(target), trackingPixel: \(trackingPixel), accupixelUrl: \(accupixelUrl), refreshUrl: \(refreshUrl), refreshTime: \(refreshTime), body: \(body)"
    }
}

