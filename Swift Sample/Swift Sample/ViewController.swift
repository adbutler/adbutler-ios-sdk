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
        AdButler().requestPlacement(with: config) {
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

