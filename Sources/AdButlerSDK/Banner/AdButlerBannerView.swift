import Foundation
import UIKit

/// UIKit banner ad view. Drop into your view hierarchy and call `load(request:)`.
///
/// ```swift
/// let banner = AdButlerBannerView()
/// banner.delegate = self
/// banner.load(request: AdRequest(zoneId: 12345))
/// view.addSubview(banner)
/// ```
public class AdButlerBannerView: UIView {

    /// Delegate for receiving ad events.
    public weak var delegate: AdButlerBannerViewDelegate?

    /// Whether an ad is currently loaded.
    public private(set) var isLoaded: Bool = false

    private var controller: BannerAdController?
    private var renderedView: UIView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        clipsToBounds = true
    }

    /// Load an ad for the given request.
    public func load(request: AdRequest) {
        guard let sdk = AdButler.shared else {
            delegate?.bannerView(self, didFailWith: .notConfigured)
            return
        }

        let ctrl = BannerAdController(sdk: sdk)
        self.controller = ctrl

        ctrl.onAdLoaded = { [weak self] response in
            guard let self = self else { return }
            self.isLoaded = true

            // Clear previous ad
            self.renderedView?.removeFromSuperview()
            self.renderedView = ctrl.renderAd(in: self)

            self.delegate?.bannerView(self, didLoad: response)
        }

        ctrl.onAdFailed = { [weak self] error in
            guard let self = self else { return }
            self.isLoaded = false
            self.delegate?.bannerView(self, didFailWith: error)
        }

        ctrl.onImpression = { [weak self] in
            guard let self = self else { return }
            self.delegate?.bannerViewDidRecordImpression(self)
        }

        ctrl.onClick = { [weak self] in
            guard let self = self else { return }
            self.delegate?.bannerViewDidRecordClick(self)
        }

        ctrl.loadAd(request: request)
    }

    /// Stop auto-refresh.
    public func stopAutoRefresh() {
        controller?.stopRefresh()
    }

    public override func removeFromSuperview() {
        controller?.stopRefresh()
        super.removeFromSuperview()
    }
}

/// Delegate protocol for receiving banner ad events.
public protocol AdButlerBannerViewDelegate: AnyObject {
    /// Called when an ad has been loaded successfully.
    func bannerView(_ bannerView: AdButlerBannerView, didLoad response: AdResponse)

    /// Called when the ad request failed.
    func bannerView(_ bannerView: AdButlerBannerView, didFailWith error: AdButlerError)

    /// Called when a viewable impression has been recorded.
    func bannerViewDidRecordImpression(_ bannerView: AdButlerBannerView)

    /// Called when the user clicked the ad.
    func bannerViewDidRecordClick(_ bannerView: AdButlerBannerView)
}

/// Default empty implementations so delegates don't need all methods.
public extension AdButlerBannerViewDelegate {
    func bannerView(_ bannerView: AdButlerBannerView, didLoad response: AdResponse) {}
    func bannerView(_ bannerView: AdButlerBannerView, didFailWith error: AdButlerError) {}
    func bannerViewDidRecordImpression(_ bannerView: AdButlerBannerView) {}
    func bannerViewDidRecordClick(_ bannerView: AdButlerBannerView) {}
}
