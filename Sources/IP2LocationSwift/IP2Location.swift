import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A lightweight client for the IP2Location.io IP geolocation Lookup API.
///
/// ```swift
/// let client = IP2Location(apiKey: "YOUR_API_KEY")
///
/// // Async / await
/// let result = try await client.lookup(ip: "8.8.8.8")
/// print(result.countryName ?? "?")
///
/// // Completion handler
/// client.lookup(ip: "8.8.8.8") { result in
///     if case .success(let info) = result {
///         print(info.cityName ?? "?")
///     }
/// }
/// ```
///
/// The API supports keyless lookups (up to 1,000 queries/day). Simply omit the
/// `apiKey` to use the requestor's own IP with `lookup(ip: nil)`.
public struct IP2Location: Sendable {

    /// How the API key is transmitted to the server.
    public enum AuthStyle: Sendable {
        /// The API key is appended as a `key` URL query parameter (default).
        case queryParameter
        /// The API key is sent in the `Authorization: Bearer <key>` header.
        case bearerToken
    }

    /// The default IP2Location.io API endpoint.
    public static let defaultBaseURL = URL(string: "https://api.ip2location.io/")!

    /// The API key. `nil` performs a keyless lookup.
    public var apiKey: String?

    /// How `apiKey` is transmitted. Defaults to `.queryParameter`.
    public var authStyle: AuthStyle

    /// The default translation language, applied when a call does not specify one.
    public var lang: IP2Language?

    /// The API endpoint. Defaults to `IP2Location.defaultBaseURL`.
    public var baseURL: URL

    /// The transport used to perform requests. Defaults to `URLSession.shared`.
    public var session: any IP2LocationNetworking

    /// Creates a new IP2Location.io client.
    ///
    /// - Parameters:
    ///   - apiKey: Your IP2Location.io API key, or `nil` for keyless lookup.
    ///   - authStyle: How the API key is transmitted.
    ///   - lang: Default translation language used when a call omits `lang`.
    ///   - baseURL: API endpoint override (for testing or regional endpoints).
    ///   - session: Transport used to perform requests.
    public init(apiKey: String? = nil,
                authStyle: AuthStyle = .queryParameter,
                lang: IP2Language? = nil,
                baseURL: URL = IP2Location.defaultBaseURL,
                session: any IP2LocationNetworking = URLSession.shared) {
        self.apiKey = apiKey
        self.authStyle = authStyle
        self.lang = lang
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Lookup (async / await)

    /// Performs a geolocation lookup.
    ///
    /// - Parameters:
    ///   - ip: IP address (IPv4 or IPv6) to look up. When `nil`, the API
    ///         resolves the requester's own IP address.
    ///   - lang: Translation language override; falls back to the client's
    ///           default `lang` when `nil`.
    /// - Returns: The decoded geolocation result.
    /// - Throws: `IP2LocationError` on network or API failures.
    @discardableResult
    public func lookup(ip: String? = nil, lang: IP2Language? = nil) async throws -> IP2LocationResult {
        try await withCheckedThrowingContinuation { continuation in
            lookup(ip: ip, lang: lang) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Lookup (completion handler)

    /// Performs a geolocation lookup and delivers the outcome to `completion`.
    ///
    /// - Parameters:
    ///   - ip: IP address (IPv4 or IPv6) to look up. When `nil`, the API
    ///         resolves the requester's own IP address.
    ///   - lang: Translation language override; falls back to the client's
    ///           default `lang` when `nil`.
    ///   - completion: Invoked once with either the decoded result or an
    ///                 `IP2LocationError`.
    public func lookup(ip: String? = nil,
                       lang: IP2Language? = nil,
                       completion: @escaping (Result<IP2LocationResult, IP2LocationError>) -> Void) {
        let request: URLRequest
        do {
            request = try makeRequest(ip: ip, lang: lang)
        } catch {
            completion(.failure(error as? IP2LocationError ?? .invalidURL))
            return
        }

        session.perform(request) { data, response, error in
            if let error = error {
                completion(.failure(.transport(error)))
                return
            }
            guard let data = data, let response = response else {
                completion(.failure(.invalidResponse))
                return
            }
            do {
                completion(.success(try Self.handle(data: data, response: response)))
            } catch let error as IP2LocationError {
                completion(.failure(error))
            } catch {
                completion(.failure(.decodingFailed))
            }
        }
    }

    // MARK: - Internal

    /// Builds the GET request for a lookup.
    internal func makeRequest(ip: String?, lang: IP2Language?) throws -> URLRequest {
        let effectiveLang = lang ?? self.lang

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) ?? URLComponents()
        var items: [URLQueryItem] = []

        switch authStyle {
        case .queryParameter:
            if let apiKey {
                items.append(URLQueryItem(name: "key", value: apiKey))
            }
        case .bearerToken:
            break
        }

        if let ip {
            items.append(URLQueryItem(name: "ip", value: ip))
        }
        if let effectiveLang {
            items.append(URLQueryItem(name: "lang", value: effectiveLang.rawValue))
        }

        components.queryItems = items.isEmpty ? nil : items
        guard let url = components.url else {
            throw IP2LocationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        if authStyle == .bearerToken, let apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    /// Decodes a raw HTTP response into an `IP2LocationResult`, translating
    /// API error payloads and unexpected status codes into `IP2LocationError`.
    internal static func handle(data: Data, response: URLResponse) throws -> IP2LocationResult {
        guard let http = response as? HTTPURLResponse else {
            throw IP2LocationError.invalidResponse
        }
        let isSuccess = (200..<300).contains(http.statusCode)

        // The API returns either a lookup result or an error envelope:
        // { "error": { "error_code": ..., "error_message": ... } }.
        if let result = try? JSONDecoder().decode(IP2LocationResult.self, from: data) {
            if let apiError = result.error {
                throw IP2LocationError.apiError(
                    code: apiError.errorCode ?? 0,
                    message: apiError.errorMessage ?? "Unknown API error"
                )
            }
            guard isSuccess else {
                throw IP2LocationError.httpStatus(http.statusCode)
            }
            return result
        }

        guard isSuccess else {
            throw IP2LocationError.httpStatus(http.statusCode)
        }
        throw IP2LocationError.decodingFailed
    }
}
