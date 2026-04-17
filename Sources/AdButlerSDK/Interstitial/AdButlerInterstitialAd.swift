import Foundation
import UIKit

/// A fullscreen interstitial ad.
///
/// ```swift
/// let ad = try await AdButlerInterstitialAd.load(request: AdRequest(zoneId: 67890))
/// ad.delegate = self
/// ad.present(from: viewController)
/// ```
public class AdButlerInterstitialAd {
    /// Delegate for receiving interstitial events.
    public weak var delegate: AdButlerInterstitialAdDelegate?

    /// Whether the ad is ready to be presented.
    public private(set) var isReady: Bool = false

    private let adResponse: AdResponse
    private let sdk: AdButler

    private init(response: AdResponse, sdk: AdButler) {
        self.adResponse = response
        self.sdk = sdk
        self.isReady = true
    }

    /// Load an interstitial ad.
    /// - Parameter request: The ad request configuration.
    /// - Returns: A loaded interstitial ad ready to present.
    public static func load(request: AdRequest) async throws -> AdButlerInterstitialAd {
        let sdk = try AdButler.requireShared()
        let response = try await sdk.client.fetchAd(request: request, accountId: sdk.accountId)

        // Fire impression pixel on load
        sdk.trackingManager.fireImpression(for: response)

        return AdButlerInterstitialAd(response: response, sdk: sdk)
    }

    /// Present the interstitial ad fullscreen.
    /// - Parameter viewController: The view controller to present from.
    public func present(from viewController: UIViewController) {
        guard isReady else { return }
        isReady = false

        let interstitialVC = InterstitialViewController(
            adResponse: adResponse,
            sdk: sdk
        )
        interstitialVC.modalPresentationStyle = .fullScreen
        interstitialVC.onDismiss = { [weak self] in
            guard let self = self else { return }
            self.delegate?.interstitialDidDismiss(self)
        }
        interstitialVC.onImpression = { [weak self] in
            guard let self = self else { return }
            self.delegate?.interstitialDidRecordImpression(self)
        }
        interstitialVC.onClick = { [weak self] in
            guard let self = self else { return }
            self.delegate?.interstitialDidRecordClick(self)
        }

        viewController.present(interstitialVC, animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.interstitialDidPresent(self)
        }
    }
}

/// Delegate protocol for interstitial ad events.
public protocol AdButlerInterstitialAdDelegate: AnyObject {
    func interstitialDidPresent(_ ad: AdButlerInterstitialAd)
    func interstitialDidDismiss(_ ad: AdButlerInterstitialAd)
    func interstitialDidRecordImpression(_ ad: AdButlerInterstitialAd)
    func interstitialDidRecordClick(_ ad: AdButlerInterstitialAd)
}

public extension AdButlerInterstitialAdDelegate {
    func interstitialDidPresent(_ ad: AdButlerInterstitialAd) {}
    func interstitialDidDismiss(_ ad: AdButlerInterstitialAd) {}
    func interstitialDidRecordImpression(_ ad: AdButlerInterstitialAd) {}
    func interstitialDidRecordClick(_ ad: AdButlerInterstitialAd) {}
}
