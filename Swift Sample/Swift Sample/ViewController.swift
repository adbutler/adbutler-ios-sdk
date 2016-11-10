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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let config = PlacementRequestConfig(accountId: 153105, zoneId: 214764, width: 300, height: 250)
        AdButler().requestPlacement(with: config) { response in
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension Placement {
    var debugString: String {
        return "bannerId: \(bannerId), redirectUrl: \(redirectUrl), imageUrl: \(imageUrl), width: \(width), height: \(height), altText: \(altText), target: \(target), trackingPixel: \(trackingPixel), accupixelUrl: \(accupixelUrl), refreshUrl: \(refreshUrl), refreshTime: \(refreshTime), body: \(body)"
    }
}

