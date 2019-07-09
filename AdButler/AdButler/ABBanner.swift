import Foundation
import UIKit

public class ABBanner: NSObject {
    private var imageView:UIView? = nil
    private var viewController:UIViewController? = nil
    
    public init(placement:Placement, parentViewController:UIViewController, frame:CGRect, respectSafeAreaLayoutGuide:Bool = false){
        super.init()
        if(placement.body != nil){
            let banner = ABMRAIDBanner()
            self.viewController = banner
            banner.initialize(placement:placement, parentViewController:parentViewController, frame:frame, respectSafeArea:respectSafeAreaLayoutGuide)
            placement.recordImpression()
        }else if(placement.imageUrl != nil){
            placement.getImageView { imageView in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                imageView.frame = frame
                self.imageView = imageView
                parentViewController.view.addSubview(imageView)
                placement.recordImpression()
            }
        }
    }
    
    public init(placement:Placement, parentViewController:UIViewController, position:String, respectSafeAreaLayoutGuide:Bool = false){
        super.init()
        if(placement.body != nil){
            let banner = ABMRAIDBanner()
            self.viewController = banner
            banner.initialize(placement:placement, parentViewController:parentViewController, position:position, respectSafeArea:respectSafeAreaLayoutGuide)
            placement.recordImpression()
        }else if(placement.imageUrl != nil){
            var x:CGFloat = 0
            var y:CGFloat = 0
            let parentRect = parentViewController.view.bounds
            if(position.range(of:"top") != nil){
                y = 0
            }
            if(position.range(of:"bottom") != nil){
                y = parentRect.height - CGFloat(placement.height)
            }
            if(position.range(of:"center") != nil){
                x = (parentRect.width / 2) - CGFloat((placement.width / 2))
                if(position == Positions.CENTER){
                    y = (parentRect.height / 2) - CGFloat((placement.height / 2))
                }
            }
            if(position.range(of:"left") != nil){
                x = 0
            }
            if(position.range(of:"right") != nil){
                x = parentRect.width - CGFloat(placement.width)
            }
            //return CGPoint(x:x, y:y)
            placement.getImageView { imageView in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.imageView = imageView
                parentViewController.view.addSubview(imageView)
                imageView.frame = CGRect(x:x, y:y, width:CGFloat(placement.width), height:CGFloat(placement.height))
                placement.recordImpression()
            }
        }
    }
    
    public func destroy(){
        if(self.imageView != nil) {
            self.imageView!.removeFromSuperview()
        }
        if(self.viewController != nil) {
            self.viewController!.removeFromParent()
            self.viewController!.view.removeFromSuperview()
        }
    }
}
