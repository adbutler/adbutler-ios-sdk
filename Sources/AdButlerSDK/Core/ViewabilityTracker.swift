import Foundation
import UIKit

/// Tracks viewability of an ad view using MRC standard:
/// 50%+ of the ad must be visible for 1+ continuous second.
internal final class ViewabilityTracker {
    private weak var view: UIView?
    private var displayLink: CADisplayLink?
    private var visibleStartTime: CFTimeInterval?
    private var hasFireedViewable = false
    private var onViewable: (() -> Void)?

    /// Start tracking viewability for the given view.
    /// - Parameters:
    ///   - view: The ad view to track.
    ///   - onViewable: Called once when MRC viewability threshold is met.
    func startTracking(view: UIView, onViewable: @escaping () -> Void) {
        stopTracking()
        self.view = view
        self.onViewable = onViewable
        self.hasFireedViewable = false
        self.visibleStartTime = nil

        let link = CADisplayLink(target: self, selector: #selector(checkVisibility))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 5, maximum: 10)
        link.add(to: .main, forMode: .common)
        self.displayLink = link
    }

    /// Stop tracking viewability.
    func stopTracking() {
        displayLink?.invalidate()
        displayLink = nil
        visibleStartTime = nil
        onViewable = nil
    }

    @objc private func checkVisibility(_ link: CADisplayLink) {
        guard !hasFireedViewable else {
            stopTracking()
            return
        }

        guard let view = view, view.window != nil else {
            visibleStartTime = nil
            return
        }

        let visiblePercent = calculateVisiblePercentage(of: view)

        if visiblePercent >= 0.5 {
            if visibleStartTime == nil {
                visibleStartTime = link.timestamp
            } else if let start = visibleStartTime, (link.timestamp - start) >= 1.0 {
                hasFireedViewable = true
                onViewable?()
                stopTracking()
            }
        } else {
            visibleStartTime = nil
        }
    }

    private func calculateVisiblePercentage(of view: UIView) -> CGFloat {
        guard let window = view.window else { return 0 }

        let viewFrame = view.convert(view.bounds, to: window)
        let screenBounds = window.bounds
        let intersection = viewFrame.intersection(screenBounds)

        guard !intersection.isNull else { return 0 }

        let viewArea = viewFrame.width * viewFrame.height
        guard viewArea > 0 else { return 0 }

        let visibleArea = intersection.width * intersection.height
        return visibleArea / viewArea
    }
}
