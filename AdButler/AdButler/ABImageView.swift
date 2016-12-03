//
//  ABImageView.swift
//  AdButler
//
//  Created by Ryuichi Saito on 12/3/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

public class ABImageView: UIImageView {
    var placement: Placement?
    
    func setupGestures() {
        isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tap))
        addGestureRecognizer(tapGesture)
    }
    
    func tap() {
        placement?.recordImpression()
    }
}
