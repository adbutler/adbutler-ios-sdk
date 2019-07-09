//
//  ViewController.swift
//  SampleApp
//
//  Created by Will Prevett on 2019-05-30.
//

import UIKit
import AdButler

class ViewController: UIViewController, ABInterstitialDelegate, ABVASTDelegate, ABMRAIDDelegate, ABMRAIDInterstitialDelegate {

    var banner: ABBanner?
    var interstitial: ABInterstitial?
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onClickInterstitial(_ sender: Any) {
        let config = PlacementRequestConfig(accountId: 50088, zoneId: 354135, width:nil, height:nil, customExtras:nil)
        AdButler.requestPlacement(with: config) { response in
            switch response {
            case .success(_ , let placements):
                guard placements.count == 1 else {
                    return
                }
                guard placements[0].isValid else {
                    return
                }
                self.interstitial = ABInterstitial(placement:placements[0], parentViewController:self, delegate:self, respectSafeAreaLayoutGuide:true)
            default:
                return
            }
        }
    }
    
    @IBAction func displayInterstitial(_ sender: Any){
        if(self.interstitial != nil){
            self.interstitial!.display()
        }
    }
    
    @IBAction func onClickBanner(_ sender: Any) {
        let config = PlacementRequestConfig(accountId: 50088, zoneId: 354134, width:320, height:50, customExtras:nil)
        AdButler.requestPlacement(with: config) { response in
            switch response {
            case .success(_ , let placements):
                guard placements.count == 1 else {
                    // error
                    return
                }
                guard placements[0].isValid else {
                    // error
                    return
                }
                self.banner?.destroy();
                self.banner = ABBanner(placement:placements[0], parentViewController:self, position:Positions.BOTTOM_CENTER)
            case .badRequest(let statusCode, let responseBody):
                return
            case .invalidJson(let responseBody):
                return
            case .requestError(let error):
                return
            }
        }
    }
    
    @IBAction func onClickMRAIDBanner(_ sender: Any) {
        let config = PlacementRequestConfig(accountId: 50088, zoneId: 354195, width:nil, height:nil, customExtras:nil)
        AdButler.requestPlacement(with: config) { response in
            switch response {
            case .success(_ , let placements):
                guard placements.count == 1 else {
                    // error
                    return
                }
                guard placements[0].isValid else {
                    // error
                    return
                }
                self.banner?.destroy();
                self.banner = ABBanner(placement:placements[0], parentViewController:self, position:Positions.BOTTOM_CENTER)
            case .badRequest(let statusCode, let responseBody):
                return
            case .invalidJson(let responseBody):
                return
            case .requestError(let error):
                return
            }
        }
    }
    
    @IBAction func onClicMRAIDkResizableBanner(_ sender: Any) {
        let config = PlacementRequestConfig(accountId: 50088, zoneId: 354715, width:nil, height:nil, customExtras:nil)
        AdButler.requestPlacement(with: config) { response in
            switch response {
            case .success(_ , let placements):
                guard placements.count == 1 else {
                    // error
                    return
                }
                guard placements[0].isValid else {
                    // error
                    return
                }
                self.banner?.destroy();
                self.banner = ABBanner(placement:placements[0], parentViewController:self, position:Positions.BOTTOM_CENTER)
            case .badRequest(let statusCode, let responseBody):
                return
            case .invalidJson(let responseBody):
                return
            case .requestError(let error):
                return
            }
        }
    }
    
    @IBAction func onClicMRAIDkTwoPartExpandableBanner(_ sender: Any) {
        let config = PlacementRequestConfig(accountId: 50088, zoneId: 354716, width:nil, height:nil, customExtras:nil)
        AdButler.requestPlacement(with: config) { response in
            switch response {
            case .success(_ , let placements):
                guard placements.count == 1 else {
                    // error
                    return
                }
                guard placements[0].isValid else {
                    // error
                    return
                }
                self.banner?.destroy();
                self.banner = ABBanner(placement:placements[0], parentViewController:self, position:Positions.BOTTOM_CENTER)
            case .badRequest(let statusCode, let responseBody):
                return
            case .invalidJson(let responseBody):
                return
            case .requestError(let error):
                return
            }
        }
    }
    
    @IBAction func onClickMRAIDInterstitial(_ sender: Any) {
        let config = PlacementRequestConfig(accountId: 50088, zoneId: 354196, width:nil, height:nil, customExtras:nil)
        AdButler.requestPlacement(with: config) { response in
            switch response {
            case .success(_ , let placements):
                guard placements.count == 1 else {
                    return
                }
                guard placements[0].isValid else {
                    return
                }
                if(placements[0].body != nil && placements[0].body != ""){
                    self.interstitial = ABInterstitial(placement:placements[0], parentViewController:self, delegate:self, respectSafeAreaLayoutGuide:true)
                }
            default:
                return
            }
        }
    }
    
    @IBAction func onClickVAST(_ sender: Any){
        let vast = ABVASTVideo()
        vast.initialize(accountID: 50088, zoneID:7205, publisherID:67540, delegate:self)
        vast.play()
    }
    
    // Non MRAID interstitial delegates
    
    func interstitialReady(_ interstitial: ABInterstitial) {
        print("ready")
    }
    
    func interstitialFailedToLoad(_ interstitial: ABInterstitial) {
        print("failed")
    }
    
    func interstitialClosed(_ interstitial: ABInterstitial) {
        print("close")
    }
    
    func interstitialStartLoad(_ interstitial: ABInterstitial) {
        print("start load")
    }
    
    // VAST delegates
    
    func onMute() {
        print("mute")
    }
    
    func onUnmute() {
        print("unmute")
    }
    
    func onPause() {
        print("pause")
    }
    
    func onResume() {
        print("resume")
    }
    
    func onRewind() {
        print("rewind")
    }
    
    func onSkip() {
        print("skip")
    }
    
    func onPlayerExpand() {
        print("playerExpand")
    }
    
    func onPlayerCollapse() {
        print("playerCollapse")
    }
    
    func onNotUsed() {
        print("notUsed")
    }
    
    func onLoaded() {
        print("loaded")
    }
    
    func onStart() {
        print("start")
    }
    
    func onFirstQuartile() {
        print("firstQuartile")
    }
    
    func onMidpoint() {
        print("midpoint")
    }
    
    func onThirdQuartile() {
        print("thirdQuartile")
    }
    
    func onComplete() {
        print("complete")
    }
    
    func onCloseLinear() {
        print("closeLinear")
    }
    
    // MRAID EVENTS
    
    func open(_ url: String) {
        
    }
    
    func close() {
        
    }
    
    func expand(_ url: String?) {
        
    }
    
    func resize(to: ResizeProperties) {
        
    }
    
    func playVideo(_ url: String) {
        
    }
    
    func reportDOMSize(_ args: String?) {
        
    }
    
    func webViewLoaded() {
        
    }
    
    func interstitialReady(_ interstitial: ABMRAIDInterstitial) {
        
    }
    
    func interstitialFailedToLoad(_ interstitial: ABMRAIDInterstitial) {
        
    }
    
    func interstitialClosed(_ interstitial: ABMRAIDInterstitial) {
        
    }
    
    func interstitialStartLoad(_ interstitial: ABMRAIDInterstitial) {
        
    }
    
}
