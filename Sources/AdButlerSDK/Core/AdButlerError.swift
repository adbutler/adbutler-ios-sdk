import Foundation

/// Errors thrown by the AdButler SDK.
public enum AdButlerError: Error, LocalizedError {
    /// SDK has not been configured. Call `AdButler.configure(accountId:)` first.
    case notConfigured

    /// Network request failed.
    case networkError(underlying: Error)

    /// Server returned a non-success HTTP status.
    case serverError(statusCode: Int, body: String?)

    /// Failed to parse the ad response JSON.
    case parseError(message: String)

    /// No ad available for the requested zone.
    case noAdAvailable

    /// VAST XML parsing failed.
    case vastParseError(message: String)

    /// No compatible media file found in VAST response.
    case noCompatibleMedia

    /// Ad request was cancelled.
    case cancelled

    /// An invalid argument was provided.
    case invalidArgument(message: String)

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AdButler SDK not configured. Call AdButler.configure(accountId:) first."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code, let body):
            return "Server error (\(code)): \(body ?? "no details")"
        case .parseError(let msg):
            return "Parse error: \(msg)"
        case .noAdAvailable:
            return "No ad available for the requested zone."
        case .vastParseError(let msg):
            return "VAST parse error: \(msg)"
        case .noCompatibleMedia:
            return "No compatible media file found in VAST response."
        case .cancelled:
            return "Ad request was cancelled."
        case .invalidArgument(let msg):
            return "Invalid argument: \(msg)"
        }
    }
}
