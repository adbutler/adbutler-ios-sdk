//
//  ABVideoPlayer.swift
//  AdButler
//
//  Created by Will Prevett on 2018-08-15.
//  Copyright © 2018 Will Prevett. All rights reserved.
//

import Foundation
import WebKit

public class ABVideoPlayer: UIViewController, WKUIDelegate, WKNavigationDelegate {
    private var videoView:WKWebView?
    private var constraints:[NSLayoutConstraint]? = []
    private var onClose:() -> Void = {}
    private var originalRootController:UIViewController!
    let fullScreenSize = CGRect(x:0, y:0, width:UIScreen.main.bounds.width, height:UIScreen.main.bounds.height)
    private var delegate:ABVASTDelegate?
    
    internal var addCloseButtonToVideo = true
    
    public func initialize(onClose:@escaping () -> Void){
        self.originalRootController = UIApplication.shared.delegate?.window??.rootViewController
        
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypes.init(rawValue: 0)
        
        self.onClose = onClose
        
        videoView = WKWebView(frame:fullScreenSize, configuration:config)
        
        view.autoresizesSubviews = true
        view.isUserInteractionEnabled = true
        view.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleWidth, .flexibleHeight]
        
        videoView!.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleWidth, .flexibleHeight]
        videoView!.uiDelegate = self
        videoView!.navigationDelegate = self
        
        view.addSubview(videoView!)
    }
    
    public override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Capture window.open (clickthroughs) and redirect
        webView.load(navigationAction.request)
        return nil
    }
    
    /* Handle HTTP requests from the webview */
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url?.absoluteString
        if(url != nil && !url!.starts(with:"about:blank") && url! != "https://servedbyadbutler.com/"){
            if (url!.range(of:"itunes.apple.com") != nil){
                if let url = URL(string: url!), UIApplication.shared.canOpenURL(url) {
                    if #available(iOS 10, *) {
                        UIApplication.shared.open(url)
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }
            }
            else if (url!.range(of:"vast://") != nil){
                let range = url!.range(of:"vast://")
                let from = range?.upperBound
                let to = url!.endIndex
                let event = String(url![from!..<to])
                handleEvent(event)
            }else if (url!.range(of:"callback.spark") == nil && url!.range(of:"callback-p.spark") == nil){
                let browser = ABMRAIDBrowserWindow()
                browser.initialize()
                browser.loadUrl(url!)
                browser.onClose(perform:{() in
                    ABMRAIDUtilities.setRootController(self.originalRootController!)
                })
                ABMRAIDUtilities.setRootController(browser)
            }
        }
        decisionHandler(.allow)
        return
    }
    
    public func playVideo(_ url:URL, onClose:@escaping () -> Void){
        self.initialize(onClose:onClose);
        let request:URLRequest = URLRequest(url:url)
        videoView!.load(request)
        if(addCloseButtonToVideo){
            addCloseButton()
        }
    }
    
    public func playHTMLVideo(_ body:String, delegate:ABVASTDelegate?, onClose:@escaping() -> Void){
        self.initialize(onClose:onClose)
        self.delegate = delegate
        videoView!.loadHTMLString(body, baseURL:nil)
        if(addCloseButtonToVideo){
            addCloseButton()
        }
    }
    
    internal func addCloseButton(){
        let w = videoView!.bounds.width
        let closeW = CGFloat(50)
        let closeH = CGFloat(50)
        
        let closeX = w - closeW
        let closeY = videoView!.bounds.minY + 3
        let buttonRect = CGRect(x:closeX, y:closeY, width:closeW, height:closeH)
        
        let closeButton = UIButton(frame:buttonRect)
        closeButton.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin]
        closeButton.setTitleColor(UIColor.white, for:UIControl.State.normal)
        closeButton.setBackgroundImage(UIImage(named:"closeButtonBG", in: Bundle(identifier:"phunware.ios.mraid.sdk"), compatibleWith:nil), for: UIControl.State.normal)
        closeButton.setTitle("X", for:UIControl.State.normal)
        closeButton.titleLabel!.textAlignment = NSTextAlignment.center
        closeButton.titleLabel!.font = UIFont.init(descriptor: UIFontDescriptor(name:"Gill Sans", size:24.0), size: 24.0)
        
        closeButton.addTarget(self, action: #selector(close), for:UIControl.Event.touchUpInside)
        videoView!.addSubview(closeButton)
    }
    
    @objc func close(){
        videoView!.removeFromSuperview()
        videoView = nil
        removeFromParent()
        onClose()
    }
    
    public var webView:WKWebView {
        return videoView!
    }
    
    public func webViewDidClose(_ webView: WKWebView) {
        NSLog("Video view closed.")
    }
    
    public override var shouldAutorotate: Bool {
        return true
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
    }
    
    func handleEvent(_ event:String){
        switch(event){
        case "mute":
            self.delegate?.onMute()
        case "unmute":
            self.delegate?.onUnmute()
        case "pause":
            self.delegate?.onPause()
        case "resume":
            self.delegate?.onResume()
            
        case "rewind":
            self.delegate?.onRewind()
            
        case "skip":
            self.delegate?.onSkip()
            close()
        case "playerExpand":
            self.delegate?.onPlayerExpand()
            
        case "playerCollapse":
            self.delegate?.onPlayerCollapse()
            
        case "notUsed":
            self.delegate?.onNotUsed()
            
        case "loaded":
            self.delegate?.onLoaded()
            
        case "start":
            self.delegate?.onStart()
            
        case "firstQuartile":
            self.delegate?.onFirstQuartile()
            
        case "midpoint":
            self.delegate?.onMidpoint()
            
        case "thirdQuartile":
            self.delegate?.onThirdQuartile()
            
        case "complete":
            self.delegate?.onComplete()
            close()
        case "closeLinear":
            self.delegate?.onCloseLinear()
        default:
            break
        }
    }
}
