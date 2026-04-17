import SwiftUI

/// SwiftUI banner ad view.
///
/// ```swift
/// AdButlerBanner(request: AdRequest(zoneId: 12345)) { event in
///     switch event {
///     case .loaded(let response):
///         print("Ad loaded: \(response.bannerId)")
///     case .failed(let error):
///         print("Ad failed: \(error)")
///     case .impression:
///         print("Viewable impression recorded")
///     case .click:
///         print("Ad clicked")
///     }
/// }
/// ```
public struct AdButlerBanner: UIViewRepresentable {
    private let request: AdRequest
    private let onEvent: ((AdButlerBannerEvent) -> Void)?

    /// Create a banner ad view.
    /// - Parameters:
    ///   - request: The ad request configuration.
    ///   - onEvent: Optional callback for ad lifecycle events.
    public init(request: AdRequest, onEvent: ((AdButlerBannerEvent) -> Void)? = nil) {
        self.request = request
        self.onEvent = onEvent
    }

    public func makeUIView(context: Context) -> AdButlerBannerView {
        let bannerView = AdButlerBannerView()
        bannerView.delegate = context.coordinator
        return bannerView
    }

    public func updateUIView(_ uiView: AdButlerBannerView, context: Context) {
        if !uiView.isLoaded {
            uiView.load(request: request)
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onEvent: onEvent)
    }

    public class Coordinator: NSObject, AdButlerBannerViewDelegate {
        let onEvent: ((AdButlerBannerEvent) -> Void)?

        init(onEvent: ((AdButlerBannerEvent) -> Void)?) {
            self.onEvent = onEvent
        }

        public func bannerView(_ bannerView: AdButlerBannerView, didLoad response: AdResponse) {
            onEvent?(.loaded(response))
        }

        public func bannerView(_ bannerView: AdButlerBannerView, didFailWith error: AdButlerError) {
            onEvent?(.failed(error))
        }

        public func bannerViewDidRecordImpression(_ bannerView: AdButlerBannerView) {
            onEvent?(.impression)
        }

        public func bannerViewDidRecordClick(_ bannerView: AdButlerBannerView) {
            onEvent?(.click)
        }
    }
}

/// Events emitted by the SwiftUI banner ad view.
public enum AdButlerBannerEvent {
    /// Ad loaded successfully.
    case loaded(AdResponse)
    /// Ad request failed.
    case failed(AdButlerError)
    /// Viewable impression recorded (MRC standard met).
    case impression
    /// User clicked the ad.
    case click
}
