//
//  Placement+ImageView.swift
//  AdButler
//
//  Created by Ryuichi Saito on 12/3/16.
//  Copyright © 2016 AdButler. All rights reserved.
//

import Foundation

public extension Placement {
    /**
     Asynchronously downloads the image for this `Placement`, and generates the corresponding image view with default gestures associated to it.
     
     - Parameter completionHandler: a success callback block. The block will be given a `UIImageView`.
     */
    @objc(getImageView:)
    public func getImageView(completionHandler complete: @escaping (UIImageView) -> Void) {
        guard let imageUrl = imageUrl, let url = URL(string: imageUrl) else {
            return
        }
        
        let session = URLSession(configuration: .ephemeral)
        let task = session.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print("Error requeseting an image with url \(url.absoluteString)")
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
