import Foundation

/// Main entry point for the AdButler SDK.
/// Call `AdButler.configure(accountId:)` before using any ad components.
public final class AdButler {
    /// Shared configuration instance.
    public private(set) static var shared: AdButler?

    /// The AdButler account ID.
    public let accountId: Int

    /// SDK options.
    public let options: AdButlerOptions

    /// Internal HTTP client.
    internal let client: AdButlerClient

    /// Internal tracking manager.
    internal let trackingManager: TrackingManager

    /// Internal frequency cap manager.
    internal let frequencyCapManager: FrequencyCapManager

    private init(accountId: Int, options: AdButlerOptions) {
        self.accountId = accountId
        self.options = options
        self.client = AdButlerClient(
            baseUrl: options.baseUrl,
            logLevel: options.logLevel
        )
        self.trackingManager = TrackingManager(client: client)
        self.frequencyCapManager = FrequencyCapManager()
    }

    /// Configure the AdButler SDK with your account ID.
    /// Must be called before creating any ad views.
    /// - Parameters:
    ///   - accountId: Your AdButler account ID.
    ///   - options: Optional configuration options.
    public static func configure(accountId: Int, options: AdButlerOptions = .init()) {
        shared = AdButler(accountId: accountId, options: options)
        if options.logLevel != .none {
            print("[AdButler] SDK configured for account \(accountId)")
        }
    }

    /// Returns the shared instance, or throws if not configured.
    internal static func requireShared() throws -> AdButler {
        guard let shared = shared else {
            throw AdButlerError.notConfigured
        }
        return shared
    }
}

/// Configuration options for the AdButler SDK.
public struct AdButlerOptions {
    /// Base URL for ad serving. Override for testing.
    public var baseUrl: String

    /// Enable test mode (no real impressions tracked).
    public var testMode: Bool

    /// Log level for SDK diagnostics.
    public var logLevel: AdButlerLogLevel

    public init(
        baseUrl: String = "https://servedbyadbutler.com",
        testMode: Bool = false,
        logLevel: AdButlerLogLevel = .none
    ) {
        self.baseUrl = baseUrl
        self.testMode = testMode
        self.logLevel = logLevel
    }
}

/// SDK log levels.
public enum AdButlerLogLevel: Int, Sendable {
    case none = 0
    case error = 1
    case warning = 2
    case info = 3
    case debug = 4
}
