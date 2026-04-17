import Foundation
import UIKit

/// Selects the best media file from a VAST response based on device capabilities.
internal struct MediaFileSelector {
    /// Supported MIME types in order of preference.
    private static let preferredTypes = ["video/mp4", "video/m4v", "video/quicktime", "video/webm"]

    /// Select the best media file for the current device.
    /// - Parameters:
    ///   - mediaFiles: Available media files from VAST response.
    ///   - maxBitrate: Maximum acceptable bitrate in kbps (nil = no limit).
    /// - Returns: The best matching media file, or nil if none are compatible.
    static func selectBest(from mediaFiles: [VASTMediaFile], maxBitrate: Int? = nil) -> VASTMediaFile? {
        guard !mediaFiles.isEmpty else { return nil }

        let screenWidth = Int(UIScreen.main.bounds.width * UIScreen.main.scale)
        let screenHeight = Int(UIScreen.main.bounds.height * UIScreen.main.scale)

        // Filter to supported MIME types
        let compatible = mediaFiles.filter { file in
            preferredTypes.contains(file.mimeType.lowercased())
        }

        guard !compatible.isEmpty else {
            // Fall back to any progressive media file
            return mediaFiles.first { $0.delivery == "progressive" } ?? mediaFiles.first
        }

        // Filter by bitrate if max specified
        let bitrateFiltered: [VASTMediaFile]
        if let max = maxBitrate {
            bitrateFiltered = compatible.filter { ($0.bitrate ?? 0) <= max }
            if bitrateFiltered.isEmpty {
                // All files exceed bitrate, use the lowest bitrate one
                return compatible.min { ($0.bitrate ?? 0) < ($1.bitrate ?? 0) }
            }
        } else {
            bitrateFiltered = compatible
        }

        // Score by closeness to screen dimensions + prefer higher bitrate
        let scored = bitrateFiltered.map { file -> (file: VASTMediaFile, score: Int) in
            let dimScore = abs(file.width - screenWidth) + abs(file.height - screenHeight)
            // Lower dimScore = better fit. Higher bitrate = better quality (subtract from score).
            let bitrateBonus = file.bitrate ?? 0
            return (file: file, score: dimScore - bitrateBonus / 10)
        }

        return scored.min { $0.score < $1.score }?.file
    }
}
