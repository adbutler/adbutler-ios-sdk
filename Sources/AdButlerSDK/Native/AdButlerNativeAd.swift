import Foundation
import UIKit
import WebKit

/// A native ad that renders HTML content in a WKWebView.
///
/// ```swift
/// let nativeAd = try await AdButlerNativeAd.load(request: AdRequest(zoneId: 11111))
/// nativeAd.present(in: containerView)
/// ```
public class AdButlerNativeAd {
    /// The raw HTML body of the native ad.
    public let rawHtml: String?

    /// The click-through redirect URL.
    public let clickUrl: String?

    /// The banner/ad item ID.
    public let bannerId: Int

    /// Ad width.
    public let width: Int

    /// Ad height.
    public let height: Int

    private let adResponse: AdResponse
    private let sdk: AdButler
    private var webView: WKWebView?
    private var viewabilityTracker: ViewabilityTracker?

    /// Callback when the ad is clicked.
    public var onClick: (() -> Void)?

    /// Callback when a viewable impression is recorded.
    public var onImpression: (() -> Void)?

    private init(response: AdResponse, sdk: AdButler) {
        self.adResponse = response
        self.sdk = sdk
        self.rawHtml = response.body
        self.clickUrl = response.redirectUrl
        self.bannerId = response.bannerId
        self.width = response.width
        self.height = response.height
    }

    /// Load a native ad.
    /// - Parameter request: The ad request configuration.
    /// - Returns: A loaded native ad ready to present.
    public static func load(request: AdRequest) async throws -> AdButlerNativeAd {
        let sdk = try AdButler.requireShared()
        let response = try await sdk.client.fetchAd(request: request, accountId: sdk.accountId)

        // Fire impression pixel
        sdk.trackingManager.fireImpression(for: response)

        return AdButlerNativeAd(response: response, sdk: sdk)
    }

    /// Render the native ad into the given container view using a WKWebView.
    /// - Parameter container: The UIView to render the ad into.
    /// - Returns: The WKWebView rendering the ad.
    @discardableResult
    public func present(in container: UIView) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.isOpaque = false
        wv.backgroundColor = .clear
        wv.scrollView.isScrollEnabled = false
        wv.navigationDelegate = WebViewDelegate(nativeAd: self)
        wv.translatesAutoresizingMaskIntoConstraints = false

        // Remove previous
        webView?.removeFromSuperview()
        container.addSubview(wv)

        NSLayoutConstraint.activate([
            wv.topAnchor.constraint(equalTo: container.topAnchor),
            wv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            wv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            wv.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        let html = rawHtml ?? ""
        let wrappedHtml = """
        <!DOCTYPE html>
        <html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>* { margin: 0; padding: 0; box-sizing: border-box; } body { background: transparent; }</style>
        </head><body>\(html)</body></html>
        """
        wv.loadHTMLString(wrappedHtml, baseURL: nil)
        self.webView = wv

        // Fire eligible
        sdk.trackingManager.fireEligible(for: adResponse)

        // Viewability tracking
        let tracker = ViewabilityTracker()
        tracker.startTracking(view: container) { [weak self] in
            guard let self = self else { return }
            self.sdk.trackingManager.fireViewable(for: self.adResponse)
            self.onImpression?()
        }
        self.viewabilityTracker = tracker

        return wv
    }

    /// Manually record a click (if not using the built-in WebView click handling).
    public func recordClick() {
        guard let urlStr = clickUrl, let url = URL(string: urlStr) else { return }
        onClick?()
        UIApplication.shared.open(url)
    }
}

/// Internal WKNavigationDelegate that handles link clicks.
private class WebViewDelegate: NSObject, WKNavigationDelegate {
    weak var nativeAd: AdButlerNativeAd?

    init(nativeAd: AdButlerNativeAd) {
        self.nativeAd = nativeAd
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if navigationAction.navigationType == .linkActivated {
            nativeAd?.recordClick()
            return .cancel
        }
        return .allow
    }
}
