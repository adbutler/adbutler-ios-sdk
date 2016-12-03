//
//  Placement+ImageView.swift
//  AdButler
//
//  Created by Ryuichi Saito on 12/3/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

public extension Placement {
    public func getImageView(completionHandler complete: @escaping (UIImageView) -> Void) {
        guard let imageUrl = imageUrl, let url = URL(string: imageUrl) else {
            return
        }
        
        let session = URLSession(configuration: .ephemeral)
        let task = session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, let data = data, httpResponse.statusCode == 200 else {
                return
            }
            
            let image = UIImage(data: data)
            let imageView = ABImageView(image: image)
            imageView.placement = self
            
            DispatchQueue.main.async {
                complete(imageView)
                imageView.setupGestures()
            }
        }
        task.resume()
    }
}
