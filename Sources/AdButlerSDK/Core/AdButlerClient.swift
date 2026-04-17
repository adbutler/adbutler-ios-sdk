import Foundation

/// Internal HTTP client for making ad serve requests.
internal final class AdButlerClient {
    private let baseUrl: String
    private let logLevel: AdButlerLogLevel
    private let session: URLSession

    init(baseUrl: String, logLevel: AdButlerLogLevel) {
        self.baseUrl = baseUrl
        self.logLevel = logLevel

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        config.waitsForConnectivity = false
        self.session = URLSession(configuration: config)
    }

    /// Fetch an ad for the given request.
    func fetchAd(request: AdRequest, accountId: Int) async throws -> AdResponse {
        guard let url = request.buildUrl(accountId: accountId, baseUrl: baseUrl) else {
            throw AdButlerError.invalidArgument(message: "Could not build ad request URL")
        }

        log(.debug, "Fetching ad: \(url.absoluteString)")

        let (data, response) = try await performRequest(url: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AdButlerError.networkError(underlying: URLError(.badServerResponse))
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8)
            log(.error, "Server error \(httpResponse.statusCode): \(body ?? "no body")")
            throw AdButlerError.serverError(statusCode: httpResponse.statusCode, body: body)
        }

        let adResponse = try AdResponse.parseAdServeResponse(data: data)
        log(.info, "Ad loaded: banner_id=\(adResponse.bannerId), \(adResponse.width)x\(adResponse.height)")
        return adResponse
    }

    /// Fetch raw data from a URL (used for VAST XML, images, etc.).
    func fetchData(from url: URL) async throws -> Data {
        log(.debug, "Fetching data: \(url.absoluteString)")
        let (data, response) = try await performRequest(url: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AdButlerError.serverError(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                body: nil
            )
        }

        return data
    }

    /// Fire a tracking pixel (fire-and-forget GET request).
    func firePixel(url: URL) {
        log(.debug, "Firing pixel: \(url.absoluteString)")
        Task {
            do {
                let _ = try await performRequest(url: url)
            } catch {
                log(.warning, "Pixel fire failed: \(error.localizedDescription)")
            }
        }
    }

    private func performRequest(url: URL) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(from: url)
        } catch {
            throw AdButlerError.networkError(underlying: error)
        }
    }

    private func log(_ level: AdButlerLogLevel, _ message: String) {
        guard level.rawValue <= logLevel.rawValue else { return }
        let prefix: String
        switch level {
        case .error: prefix = "ERROR"
        case .warning: prefix = "WARN"
        case .info: prefix = "INFO"
        case .debug: prefix = "DEBUG"
        case .none: return
        }
        print("[AdButler/\(prefix)] \(message)")
    }
}
