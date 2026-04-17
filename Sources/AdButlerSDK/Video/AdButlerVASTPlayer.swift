import Foundation
import UIKit
import AVFoundation

/// A VAST video ad player view.
/// Supports VAST 2.0 and 4.2 with linear video, skip button,
/// quartile tracking, and companion ads.
///
/// ```swift
/// let player = AdButlerVASTPlayer()
/// player.delegate = self
/// player.load(zoneId: 99999)
/// view.addSubview(player)
/// ```
public class AdButlerVASTPlayer: UIView {

    /// Delegate for receiving video ad events.
    public weak var delegate: AdButlerVASTPlayerDelegate?

    /// Whether a video is currently playing.
    public private(set) var isPlaying = false

    /// Video duration in seconds.
    public private(set) var duration: TimeInterval = 0

    /// Current playback position in seconds.
    public var currentTime: TimeInterval {
        avPlayer?.currentTime().seconds ?? 0
    }

    // MARK: - Private

    private var avPlayer: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    private var vastAd: VASTAd?
    private var sdk: AdButler?

    // Quartile tracking
    private var firedQuartiles: Set<VASTQuartile> = []

    // Skip button
    private var skipButton: UIButton?
    private var skipOffset: TimeInterval?
    private var skipCountdownTimer: Timer?

    // Companion
    private var companionView: UIView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .black
        clipsToBounds = true
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    // MARK: - Public API

    /// Load a VAST ad from an AdButler VAST zone.
    /// - Parameter zoneId: The VAST zone ID.
    public func load(zoneId: Int) {
        guard let sdk = AdButler.shared else {
            delegate?.vastPlayer(self, didFailWith: .notConfigured)
            return
        }
        self.sdk = sdk

        Task {
            do {
                // Fetch the VAST zone tag to get the VAST XML URL
                let tagUrl = URL(string: "\(sdk.options.baseUrl)/vast.spark?setID=\(zoneId);ID=\(sdk.accountId)")!
                let xmlData = try await sdk.client.fetchData(from: tagUrl)
                try await parseAndLoad(xmlData: xmlData, sdk: sdk)
            } catch let error as AdButlerError {
                await MainActor.run { delegate?.vastPlayer(self, didFailWith: error) }
            } catch {
                await MainActor.run { delegate?.vastPlayer(self, didFailWith: .networkError(underlying: error)) }
            }
        }
    }

    /// Load a VAST ad from a direct VAST XML URL.
    /// - Parameter vastUrl: URL to the VAST XML.
    public func load(vastUrl: URL) {
        guard let sdk = AdButler.shared else {
            delegate?.vastPlayer(self, didFailWith: .notConfigured)
            return
        }
        self.sdk = sdk

        Task {
            do {
                let xmlData = try await sdk.client.fetchData(from: vastUrl)
                try await parseAndLoad(xmlData: xmlData, sdk: sdk)
            } catch let error as AdButlerError {
                await MainActor.run { delegate?.vastPlayer(self, didFailWith: error) }
            } catch {
                await MainActor.run { delegate?.vastPlayer(self, didFailWith: .networkError(underlying: error)) }
            }
        }
    }

    /// Start or resume playback.
    public func play() {
        avPlayer?.play()
        isPlaying = true
    }

    /// Pause playback.
    public func pause() {
        avPlayer?.pause()
        isPlaying = false
        fireTrackingEvent("pause")
    }

    /// Present the video fullscreen.
    public func presentFullscreen(from viewController: UIViewController) {
        let vc = VASTPlayerViewController(player: self)
        vc.modalPresentationStyle = .fullScreen
        viewController.present(vc, animated: true)
    }

    // MARK: - Internal

    private func parseAndLoad(xmlData: Data, sdk: AdButler) async throws {
        let parser = VASTParser()
        let vastResponse = try parser.parse(data: xmlData)

        guard let ad = vastResponse.ads.first else {
            throw AdButlerError.noAdAvailable
        }

        // Handle wrapper (follow redirect)
        if ad.isWrapper, let wrapperUrlStr = ad.wrapperUrl, let wrapperUrl = URL(string: wrapperUrlStr) {
            let wrappedData = try await sdk.client.fetchData(from: wrapperUrl)
            try await parseAndLoad(xmlData: wrappedData, sdk: sdk)
            return
        }

        guard let linear = ad.linear else {
            throw AdButlerError.vastParseError(message: "No linear creative found")
        }

        guard let mediaFile = MediaFileSelector.selectBest(from: linear.mediaFiles) else {
            throw AdButlerError.noCompatibleMedia
        }

        guard let mediaUrl = URL(string: mediaFile.url) else {
            throw AdButlerError.vastParseError(message: "Invalid media file URL")
        }

        await MainActor.run {
            self.vastAd = ad
            self.duration = linear.duration
            self.skipOffset = linear.skipOffset
            self.firedQuartiles = []

            setupPlayer(url: mediaUrl)
            delegate?.vastPlayerDidLoad(self, ad: ad)
        }
    }

    @MainActor
    private func setupPlayer(url: URL) {
        // Clean up previous player
        cleanup()

        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        self.avPlayer = player

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        layer.frame = bounds
        self.layer.addSublayer(layer)
        self.playerLayer = layer

        // Time observer for quartile tracking
        let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.handleTimeUpdate(time.seconds)
        }

        // End of playback
        NotificationCenter.default.addObserver(
            self, selector: #selector(playerDidFinish),
            name: .AVPlayerItemDidPlayToEndTime, object: playerItem
        )

        // Set up skip button if skippable
        if skipOffset != nil {
            setupSkipButton()
        }

        // Fire impression URLs
        if let ad = vastAd {
            for url in ad.impressionUrls {
                sdk?.trackingManager.fireTrackingUrl(url)
            }
        }
        fireTrackingEvent("creativeView")
    }

    private func handleTimeUpdate(_ currentSeconds: Double) {
        guard duration > 0 else { return }

        let progress = currentSeconds / duration

        // Fire quartile events (one-shot)
        if progress > 0 && !firedQuartiles.contains(.start) {
            firedQuartiles.insert(.start)
            fireTrackingEvent("start")
            delegate?.vastPlayerDidStart(self)
        }
        if progress >= 0.25 && !firedQuartiles.contains(.firstQuartile) {
            firedQuartiles.insert(.firstQuartile)
            fireTrackingEvent("firstQuartile")
            delegate?.vastPlayerDidReachQuartile(self, quartile: .firstQuartile)
        }
        if progress >= 0.50 && !firedQuartiles.contains(.midpoint) {
            firedQuartiles.insert(.midpoint)
            fireTrackingEvent("midpoint")
            delegate?.vastPlayerDidReachQuartile(self, quartile: .midpoint)
        }
        if progress >= 0.75 && !firedQuartiles.contains(.thirdQuartile) {
            firedQuartiles.insert(.thirdQuartile)
            fireTrackingEvent("thirdQuartile")
            delegate?.vastPlayerDidReachQuartile(self, quartile: .thirdQuartile)
        }

        // Update skip button countdown
        updateSkipButton(currentSeconds: currentSeconds)
    }

    @objc private func playerDidFinish() {
        isPlaying = false
        if !firedQuartiles.contains(.complete) {
            firedQuartiles.insert(.complete)
            fireTrackingEvent("complete")
            delegate?.vastPlayerDidReachQuartile(self, quartile: .complete)
        }
        delegate?.vastPlayerDidComplete(self)

        // Show companion if available
        showCompanionAd()
    }

    // MARK: - Skip Button

    private func setupSkipButton() {
        let btn = UIButton(type: .system)
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        btn.layer.cornerRadius = 4
        btn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isEnabled = false
        btn.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        addSubview(btn)

        NSLayoutConstraint.activate([
            btn.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            btn.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])

        self.skipButton = btn
        updateSkipButton(currentSeconds: 0)
    }

    private func updateSkipButton(currentSeconds: Double) {
        guard let offset = skipOffset, let btn = skipButton else { return }

        let remaining = Int(ceil(offset - currentSeconds))

        if remaining > 0 {
            btn.setTitle("Skip in \(remaining)s", for: .normal)
            btn.isEnabled = false
            btn.alpha = 0.7
        } else {
            btn.setTitle("Skip Ad ▶", for: .normal)
            btn.isEnabled = true
            btn.alpha = 1.0
        }
    }

    @objc private func skipTapped() {
        avPlayer?.pause()
        isPlaying = false
        fireTrackingEvent("skip")
        delegate?.vastPlayerDidSkip(self)
    }

    // MARK: - Click Handling

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        // Check if touch is on skip button
        if let touch = touches.first, let btn = skipButton {
            let point = touch.location(in: btn)
            if btn.bounds.contains(point) { return }
        }

        guard let linear = vastAd?.linear,
              let clickStr = linear.clickThrough,
              let url = URL(string: clickStr) else { return }

        // Fire click tracking
        for trackingUrl in linear.clickTracking {
            sdk?.trackingManager.fireTrackingUrl(trackingUrl)
        }
        fireTrackingEvent("click")

        delegate?.vastPlayerDidClick(self)
        UIApplication.shared.open(url)
    }

    // MARK: - Companion Ads

    private func showCompanionAd() {
        guard let companions = vastAd?.companions, let companion = companions.first else { return }

        delegate?.vastPlayerDidShowCompanion(self, companion: companion)
    }

    // MARK: - Tracking

    private func fireTrackingEvent(_ event: String) {
        guard let linear = vastAd?.linear,
              let urls = linear.trackingEvents[event] else { return }
        for url in urls {
            sdk?.trackingManager.fireTrackingUrl(url)
        }
    }

    // MARK: - Cleanup

    private func cleanup() {
        if let observer = timeObserver {
            avPlayer?.removeTimeObserver(observer)
            timeObserver = nil
        }
        avPlayer?.pause()
        avPlayer = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        skipButton?.removeFromSuperview()
        skipButton = nil
        companionView?.removeFromSuperview()
        companionView = nil
        NotificationCenter.default.removeObserver(self)
    }

    deinit {
        cleanup()
    }
}

/// Delegate protocol for VAST video player events.
public protocol AdButlerVASTPlayerDelegate: AnyObject {
    func vastPlayerDidLoad(_ player: AdButlerVASTPlayer, ad: VASTAd)
    func vastPlayerDidStart(_ player: AdButlerVASTPlayer)
    func vastPlayerDidReachQuartile(_ player: AdButlerVASTPlayer, quartile: VASTQuartile)
    func vastPlayerDidComplete(_ player: AdButlerVASTPlayer)
    func vastPlayerDidClick(_ player: AdButlerVASTPlayer)
    func vastPlayerDidSkip(_ player: AdButlerVASTPlayer)
    func vastPlayer(_ player: AdButlerVASTPlayer, didFailWith error: AdButlerError)
    func vastPlayerDidShowCompanion(_ player: AdButlerVASTPlayer, companion: VASTCompanion)
}

/// Default empty implementations.
public extension AdButlerVASTPlayerDelegate {
    func vastPlayerDidLoad(_ player: AdButlerVASTPlayer, ad: VASTAd) {}
    func vastPlayerDidStart(_ player: AdButlerVASTPlayer) {}
    func vastPlayerDidReachQuartile(_ player: AdButlerVASTPlayer, quartile: VASTQuartile) {}
    func vastPlayerDidComplete(_ player: AdButlerVASTPlayer) {}
    func vastPlayerDidClick(_ player: AdButlerVASTPlayer) {}
    func vastPlayerDidSkip(_ player: AdButlerVASTPlayer) {}
    func vastPlayer(_ player: AdButlerVASTPlayer, didFailWith error: AdButlerError) {}
    func vastPlayerDidShowCompanion(_ player: AdButlerVASTPlayer, companion: VASTCompanion) {}
}
