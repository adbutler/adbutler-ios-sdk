import Foundation

/// Manages firing tracking pixels for impressions, viewability, and clicks.
internal final class TrackingManager {
    private let client: AdButlerClient
    private var firedPixels: Set<String> = []

    init(client: AdButlerClient) {
        self.client = client
    }

    /// Fire the impression pixel (accupixel_url). Should be called before rendering.
    func fireImpression(for response: AdResponse) {
        if let urlStr = response.accupixelUrl {
            fireOnce(urlStr)
        }
        if let urlStr = response.trackingPixel {
            fireOnce(urlStr)
        }
    }

    /// Fire the eligible URL when the ad view renders on screen.
    func fireEligible(for response: AdResponse) {
        if let urlStr = response.eligibleUrl {
            fireOnce(urlStr)
        }
    }

    /// Fire the viewable URL when 50%+ of the ad is visible for 1+ second.
    func fireViewable(for response: AdResponse) {
        if let urlStr = response.viewableUrl {
            fireOnce(urlStr)
        }
    }

    /// Fire a tracking URL (VAST events, custom tracking, etc.).
    func fireTrackingUrl(_ urlStr: String) {
        fireOnce(urlStr)
    }

    /// Reset tracked pixels (e.g., on ad refresh).
    func reset() {
        firedPixels.removeAll()
    }

    private func fireOnce(_ urlStr: String) {
        guard !firedPixels.contains(urlStr) else { return }
        guard let url = URL(string: urlStr) else { return }
        firedPixels.insert(urlStr)
        client.firePixel(url: url)
    }
}
