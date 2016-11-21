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
        AdButler.requestPlacement(with: config, completionHandler: placementResponseHandler)
    }
    
    @IBAction func requestPlacementsTapped(_ sender: Any) {
        let configs: [PlacementRequestConfig] = [
            PlacementRequestConfig(accountId: 153105, zoneId: 214764, width: 300, height: 250),
            PlacementRequestConfig(accountId: 153105, zoneId: 214764, width: 300, height: 250, keywords: ["sample2"]),
        ]
        AdButler.requestPlacements(with: configs, completionHandler: placementResponseHandler)
    }
    
    private func placementResponseHandler(response: Response) {
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
    
    @IBAction func requestPixelTapped(_ sender: Any) {
        guard let url = URL(string: "https://servedbyadbutler.com/default_banner.gif") else {
            print("Failed in getting a url")
            return
        }
        AdButler.requestPixel(with: url)
    }
    
    @IBAction func recordImpressionTapped(_ sender: Any) {
        recordPlacement(recordClosure: { $0.recordImpression() })
    }
    
    @IBAction func recordClickTapped(_ sender: Any) {
        recordPlacement(recordClosure: { $0.recordClick() })
    }
    
    private func recordPlacement(recordClosure: @escaping (Placement) -> Void) {
        let config = PlacementRequestConfig(accountId: 153105, zoneId: 214764, width: 300, height: 250, keywords: ["sample2"])
        AdButler.requestPlacement(with: config, completionHandler: { response in
            guard case let .success(status, placements) = response, status == .success else {
                return
            }
            
            placements.forEach(recordClosure)
        })
    }
}

extension Placement {
    var debugString: String {
        return "bannerId: \(bannerId), redirectUrl: \(redirectUrl), imageUrl: \(imageUrl), width: \(width), height: \(height), altText: \(altText), target: \(target), trackingPixel: \(trackingPixel), accupixelUrl: \(accupixelUrl), refreshUrl: \(refreshUrl), refreshTime: \(refreshTime), body: \(body)"
    }
}

