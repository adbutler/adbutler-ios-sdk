import Foundation
import UIKit
import WebKit

/// Internal controller that manages the banner ad lifecycle:
/// load → render → track → auto-refresh.
internal final class BannerAdController: NSObject {
    private let sdk: AdButler
    private var adResponse: AdResponse?
    private var refreshTimer: Timer?
    private var viewabilityTracker: ViewabilityTracker?

    var onAdLoaded: ((AdResponse) -> Void)?
    var onAdFailed: ((AdButlerError) -> Void)?
    var onImpression: (() -> Void)?
    var onClick: (() -> Void)?

    init(sdk: AdButler) {
        self.sdk = sdk
    }

    deinit {
        stopRefresh()
        viewabilityTracker?.stopTracking()
    }

    /// Load an ad for the given request.
    func loadAd(request: AdRequest) {
        Task { @MainActor in
            do {
                let response = try await sdk.client.fetchAd(
                    request: request,
                    accountId: sdk.accountId
                )
                self.adResponse = response

                // Fire impression pixel immediately
                sdk.trackingManager.fireImpression(for: response)

                onAdLoaded?(response)

                // Set up auto-refresh if configured
                if let refreshTime = response.refreshTime, refreshTime > 0 {
                    scheduleRefresh(interval: TimeInterval(refreshTime), request: request)
                }
            } catch let error as AdButlerError {
                onAdFailed?(error)
            } catch {
                onAdFailed?(.networkError(underlying: error))
            }
        }
    }

    /// Render the current ad response into the given container view.
    /// Returns the rendered view (UIImageView or WKWebView).
    @MainActor
    func renderAd(in container: UIView) -> UIView? {
        guard let response = adResponse else { return nil }

        // Fire eligible URL when rendered
        sdk.trackingManager.fireEligible(for: response)

        let renderedView: UIView

        if response.isHtmlAd, let html = response.body {
            let webView = createWebView(width: response.width, height: response.height)
            webView.loadHTMLString(wrapHtml(html, width: response.width, height: response.height), baseURL: nil)
            renderedView = webView
        } else if response.isImageAd, let imageUrlStr = response.imageUrl, let imageUrl = URL(string: imageUrlStr) {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.isUserInteractionEnabled = true
            loadImage(from: imageUrl, into: imageView)

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            imageView.addGestureRecognizer(tap)
            renderedView = imageView
        } else {
            return nil
        }

        renderedView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(renderedView)
        NSLayoutConstraint.activate([
            renderedView.topAnchor.constraint(equalTo: container.topAnchor),
            renderedView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            renderedView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            renderedView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        // Start viewability tracking
        let tracker = ViewabilityTracker()
        tracker.startTracking(view: container) { [weak self] in
            guard let self = self, let response = self.adResponse else { return }
            self.sdk.trackingManager.fireViewable(for: response)
            self.onImpression?()
        }
        self.viewabilityTracker = tracker

        return renderedView
    }

    /// Handle click-through.
    @objc private func handleTap() {
        guard let response = adResponse,
              let urlStr = response.redirectUrl,
              let url = URL(string: urlStr) else { return }

        onClick?()
        UIApplication.shared.open(url)
    }

    // MARK: - Auto Refresh

    private func scheduleRefresh(interval: TimeInterval, request: AdRequest) {
        stopRefresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.sdk.trackingManager.reset()
            self?.loadAd(request: request)
        }
    }

    func stopRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - WebView

    private func createWebView(width: Int, height: Int) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = self
        return webView
    }

    private func wrapHtml(_ html: String, width: Int, height: Int) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { width: 100%; height: 100%; overflow: hidden; background: transparent; }
        </style>
        </head>
        <body>\(html)</body>
        </html>
        """
    }

    // MARK: - Image Loading

    private func loadImage(from url: URL, into imageView: UIImageView) {
        Task {
            do {
                let data = try await sdk.client.fetchData(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        imageView.image = image
                    }
                }
            } catch {
                // Silently fail image load
            }
        }
    }
}

// MARK: - WKNavigationDelegate

extension BannerAdController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url {
            // Handle clicks — open in external browser
            onClick?()
            if let response = adResponse, let redirectStr = response.redirectUrl, let redirectUrl = URL(string: redirectStr) {
                await UIApplication.shared.open(redirectUrl)
            } else {
                await UIApplication.shared.open(url)
            }
            return .cancel
        }
        return .allow
    }
}
