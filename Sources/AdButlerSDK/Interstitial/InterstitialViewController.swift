import UIKit
import WebKit

/// Internal view controller that presents an interstitial ad fullscreen.
internal final class InterstitialViewController: UIViewController {
    private let adResponse: AdResponse
    private let sdk: AdButler
    private let viewabilityTracker = ViewabilityTracker()

    var onDismiss: (() -> Void)?
    var onImpression: (() -> Void)?
    var onClick: (() -> Void)?

    private var closeButton: UIButton!

    init(adResponse: AdResponse, sdk: AdButler) {
        self.adResponse = adResponse
        self.sdk = sdk
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // Render ad content
        if adResponse.isHtmlAd, let html = adResponse.body {
            let config = WKWebViewConfiguration()
            config.allowsInlineMediaPlayback = true
            config.mediaTypesRequiringUserActionForPlayback = []

            let webView = WKWebView(frame: .zero, configuration: config)
            webView.isOpaque = false
            webView.backgroundColor = .clear
            webView.scrollView.isScrollEnabled = false
            webView.navigationDelegate = self
            webView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(webView)

            NSLayoutConstraint.activate([
                webView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                webView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                webView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor),
                webView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor),
            ])

            let wrappedHtml = """
            <!DOCTYPE html>
            <html><head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>* { margin: 0; padding: 0; } body { background: transparent; display: flex; align-items: center; justify-content: center; min-height: 100vh; }</style>
            </head><body>\(html)</body></html>
            """
            webView.loadHTMLString(wrappedHtml, baseURL: nil)
        } else if adResponse.isImageAd, let urlStr = adResponse.imageUrl, let url = URL(string: urlStr) {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.isUserInteractionEnabled = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(imageView)

            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                imageView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.9),
                imageView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.9),
            ])

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleAdTap))
            imageView.addGestureRecognizer(tap)

            Task {
                if let data = try? await sdk.client.fetchData(from: url),
                   let image = UIImage(data: data) {
                    await MainActor.run { imageView.image = image }
                }
            }
        }

        // Close button
        closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 18
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Fire eligible URL
        sdk.trackingManager.fireEligible(for: adResponse)

        // Start viewability tracking
        viewabilityTracker.startTracking(view: view) { [weak self] in
            guard let self = self else { return }
            self.sdk.trackingManager.fireViewable(for: self.adResponse)
            self.onImpression?()
        }
    }

    @objc private func closeTapped() {
        viewabilityTracker.stopTracking()
        dismiss(animated: true) { [weak self] in
            self?.onDismiss?()
        }
    }

    @objc private func handleAdTap() {
        guard let urlStr = adResponse.redirectUrl, let url = URL(string: urlStr) else { return }
        onClick?()
        UIApplication.shared.open(url)
    }
}

extension InterstitialViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url {
            onClick?()
            if let redirectStr = adResponse.redirectUrl, let redirectUrl = URL(string: redirectStr) {
                await UIApplication.shared.open(redirectUrl)
            } else {
                await UIApplication.shared.open(url)
            }
            return .cancel
        }
        return .allow
    }
}
