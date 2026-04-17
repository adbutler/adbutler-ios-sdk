# AdButler iOS SDK

Native iOS SDK for serving display, native, and VAST video ads from [AdButler](https://www.adbutler.com).

[![CI](https://github.com/adbutler/adbutler-ios-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/adbutler/adbutler-ios-sdk/actions/workflows/ci.yml)

## Features

- **Banner Ads** — Inline display ads with auto-refresh (UIKit + SwiftUI)
- **Interstitial Ads** — Fullscreen ads with async load/show pattern
- **Native Ads** — HTML-rendered native ads in WKWebView
- **VAST Video Ads** — Built-in video player supporting VAST 2.0 and 4.2
  - Quartile tracking (start, 25%, 50%, 75%, complete)
  - Skip button with countdown
  - Companion ads
  - Wrapper/redirect chain following
- **Viewability Tracking** — MRC standard (50%+ visible for 1+ second)
- **Impression & Click Tracking** — Automatic pixel firing

## Requirements

- iOS 15.0+
- Swift 5.9+
- Xcode 15.0+

## Installation

### Swift Package Manager (recommended)

In Xcode: **File → Add Package Dependencies** and enter:

```
https://github.com/adbutler/adbutler-ios-sdk
```

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/adbutler/adbutler-ios-sdk", from: "1.0.0"),
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "AdButlerSDK", package: "adbutler-ios-sdk"),
        ]
    ),
]
```

### CocoaPods

```ruby
pod 'AdButlerSDK', '~> 1.0'
```

## Quick Start

### 1. Configure the SDK

Call this once at app launch, before using any ad components.

```swift
import AdButlerSDK

// In your App init or AppDelegate
AdButler.configure(accountId: 182804)

// With options
AdButler.configure(accountId: 182804, options: AdButlerOptions(
    testMode: false,
    logLevel: .debug   // .none, .error, .warning, .info, .debug
))
```

### 2. Show a Banner Ad

Your AdButler account ID and zone ID are required. Find your zone IDs in the AdButler dashboard under **Zones**.

#### SwiftUI

```swift
import AdButlerSDK

struct ContentView: View {
    var body: some View {
        VStack {
            Text("My App")
            
            AdButlerBanner(request: AdRequest(zoneId: 12345)) { event in
                switch event {
                case .loaded(let response):
                    print("Ad loaded: \(response.width)x\(response.height)")
                case .failed(let error):
                    print("Ad failed: \(error.localizedDescription)")
                case .impression:
                    print("Viewable impression recorded")
                case .click:
                    print("Ad clicked")
                }
            }
            .frame(height: 250)
        }
    }
}
```

#### UIKit

```swift
import AdButlerSDK

class ViewController: UIViewController, AdButlerBannerViewDelegate {
    private let bannerView = AdButlerBannerView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bannerView.delegate = self
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bannerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bannerView.widthAnchor.constraint(equalToConstant: 300),
            bannerView.heightAnchor.constraint(equalToConstant: 250),
        ])
        
        bannerView.load(request: AdRequest(zoneId: 12345))
    }

    func bannerView(_ bannerView: AdButlerBannerView, didLoad response: AdResponse) {
        print("Ad loaded: \(response.bannerId)")
    }

    func bannerView(_ bannerView: AdButlerBannerView, didFailWith error: AdButlerError) {
        print("Ad failed: \(error.localizedDescription)")
    }

    func bannerViewDidRecordImpression(_ bannerView: AdButlerBannerView) {
        print("Viewable impression")
    }

    func bannerViewDidRecordClick(_ bannerView: AdButlerBannerView) {
        print("Click")
    }
}
```

### 3. Show an Interstitial Ad

Interstitials use an async load/show pattern — load the ad in advance, then present when ready.

```swift
import AdButlerSDK

class GameViewController: UIViewController, AdButlerInterstitialAdDelegate {
    private var interstitialAd: AdButlerInterstitialAd?

    func loadAd() {
        Task {
            do {
                interstitialAd = try await AdButlerInterstitialAd.load(
                    request: AdRequest(zoneId: 67890)
                )
                interstitialAd?.delegate = self
                print("Interstitial ready")
            } catch {
                print("Failed to load interstitial: \(error)")
            }
        }
    }

    func showAd() {
        guard let ad = interstitialAd, ad.isReady else { return }
        ad.present(from: self)
    }

    // Delegate methods
    func interstitialDidPresent(_ ad: AdButlerInterstitialAd) {
        print("Interstitial shown")
    }

    func interstitialDidDismiss(_ ad: AdButlerInterstitialAd) {
        print("Interstitial dismissed")
        loadAd() // Pre-load the next one
    }

    func interstitialDidRecordImpression(_ ad: AdButlerInterstitialAd) {
        print("Interstitial impression")
    }

    func interstitialDidRecordClick(_ ad: AdButlerInterstitialAd) {
        print("Interstitial click")
    }
}
```

### 4. Show a Native Ad

Native ads render the ad's HTML body in a WKWebView. Place it in any container view.

```swift
import AdButlerSDK

class ArticleViewController: UIViewController {
    @IBOutlet weak var adContainer: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadNativeAd()
    }

    func loadNativeAd() {
        Task {
            do {
                let nativeAd = try await AdButlerNativeAd.load(
                    request: AdRequest(zoneId: 11111)
                )

                nativeAd.onImpression = {
                    print("Native ad viewable impression")
                }
                nativeAd.onClick = {
                    print("Native ad clicked")
                }

                // Render the ad's HTML into the container
                nativeAd.present(in: adContainer)
                
                // You can also access the raw data:
                print("Banner ID: \(nativeAd.bannerId)")
                print("HTML: \(nativeAd.rawHtml ?? "none")")
                print("Click URL: \(nativeAd.clickUrl ?? "none")")
            } catch {
                print("Failed to load native ad: \(error)")
            }
        }
    }
}
```

### 5. Play a VAST Video Ad

The built-in VAST player supports VAST 2.0 and 4.2 with quartile tracking, skip button, and companion ads.

#### Inline Video

```swift
import AdButlerSDK

class VideoViewController: UIViewController, AdButlerVASTPlayerDelegate {
    private let vastPlayer = AdButlerVASTPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        vastPlayer.delegate = self
        vastPlayer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vastPlayer)
        
        NSLayoutConstraint.activate([
            vastPlayer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            vastPlayer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            vastPlayer.widthAnchor.constraint(equalTo: view.widthAnchor),
            vastPlayer.heightAnchor.constraint(equalTo: vastPlayer.widthAnchor, multiplier: 9.0/16.0),
        ])
        
        // Load from a VAST zone
        vastPlayer.load(zoneId: 99999)
        
        // Or load from a direct VAST URL
        // vastPlayer.load(vastUrl: URL(string: "https://example.com/vast.xml")!)
    }

    // MARK: - AdButlerVASTPlayerDelegate

    func vastPlayerDidLoad(_ player: AdButlerVASTPlayer, ad: VASTAd) {
        print("VAST ad loaded: \(ad.adTitle ?? "untitled")")
        player.play()
    }

    func vastPlayerDidStart(_ player: AdButlerVASTPlayer) {
        print("Video started, duration: \(player.duration)s")
    }

    func vastPlayerDidReachQuartile(_ player: AdButlerVASTPlayer, quartile: VASTQuartile) {
        print("Quartile: \(quartile.rawValue)")
    }

    func vastPlayerDidComplete(_ player: AdButlerVASTPlayer) {
        print("Video completed")
    }

    func vastPlayerDidSkip(_ player: AdButlerVASTPlayer) {
        print("Video skipped")
    }

    func vastPlayerDidClick(_ player: AdButlerVASTPlayer) {
        print("Video clicked")
    }

    func vastPlayer(_ player: AdButlerVASTPlayer, didFailWith error: AdButlerError) {
        print("VAST error: \(error.localizedDescription)")
    }

    func vastPlayerDidShowCompanion(_ player: AdButlerVASTPlayer, companion: VASTCompanion) {
        print("Companion shown: \(companion.width)x\(companion.height)")
    }
}
```

#### Fullscreen Video

```swift
// Load and present fullscreen
let player = AdButlerVASTPlayer()
player.delegate = self
player.load(zoneId: 99999)

// In the didLoad delegate callback:
func vastPlayerDidLoad(_ player: AdButlerVASTPlayer, ad: VASTAd) {
    player.presentFullscreen(from: self)
}
```

## Ad Request Options

Use the builder pattern to add targeting and configuration to any ad request:

```swift
let request = AdRequest(zoneId: 12345)
    // Keyword targeting
    .keywords(["sports", "basketball", "nba"])
    
    // Expected ad size (helps AdButler select the right creative)
    .size(width: 300, height: 250)
    
    // Data key targeting (key-value pairs)
    .dataKeyTargeting(["category": "electronics", "page_type": "product"])
    
    // Referrer for contextual targeting
    .referrer("https://myapp.com/article/123")
    
    // Unique delivery (prevent same ad in multiple zones on same page)
    .uniqueDelivery(pageId: 1, place: 0)
```

## Tracking

The SDK automatically handles all tracking:

| Event | When It Fires | URL Field |
|-------|--------------|-----------|
| Impression | When ad data is received (before rendering) | `accupixel_url` |
| Eligible | When ad view renders on screen | `eligible_url` |
| Viewable | When 50%+ of ad is visible for 1+ second (MRC standard) | `viewable_url` |
| Third-party | Alongside impression | `tracking_pixel` |
| Click | When user taps the ad | Opens `redirect_url` |
| VAST quartiles | At 0%, 25%, 50%, 75%, 100% of video playback | VAST tracking events |

All tracking pixels fire exactly once per ad load (no duplicates). Pixels are fire-and-forget GET requests on a background queue.

## Auto-Refresh

Banner ads automatically refresh based on the `refresh_time` value returned by AdButler. To disable:

```swift
bannerView.stopAutoRefresh()
```

## Error Handling

All errors are typed as `AdButlerError`:

```swift
do {
    let ad = try await AdButlerInterstitialAd.load(request: AdRequest(zoneId: 123))
} catch AdButlerError.notConfigured {
    print("Call AdButler.configure(accountId:) first")
} catch AdButlerError.noAdAvailable {
    print("No ad available for this zone")
} catch AdButlerError.networkError(let underlying) {
    print("Network issue: \(underlying)")
} catch AdButlerError.serverError(let code, let body) {
    print("Server error \(code): \(body ?? "")")
} catch {
    print("Other error: \(error)")
}
```

## Architecture

```
AdButlerSDK/
├── Core/           — Configuration, networking, tracking, viewability
├── Banner/         — Inline banner ads (UIKit + SwiftUI)
├── Interstitial/   — Fullscreen display ads
├── Native/         — HTML-rendered native ads
└── Video/          — VAST 2.0 + 4.2 video player
```

The SDK uses no third-party dependencies. Display and native ads render via `WKWebView` (HTML) or `UIImageView` (images). Video uses `AVPlayer`. Viewability is tracked via `CADisplayLink`.

## License

MIT
