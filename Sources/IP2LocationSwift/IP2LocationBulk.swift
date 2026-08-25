import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A client for the IP2Location.io Bulk IP Geolocation Lookup API.
///
/// The bulk endpoint lets you look up up to 1,000 IPv4 or IPv6 addresses in a
/// single POST request.  It returns a dictionary keyed by the IP address,
/// where each value is the same `IP2LocationResult` shape used by the single
/// lookup API.
///
/// **Important:** the Bulk API requires a paid plan.  Keyless lookups are not
/// supported.
///
/// ```swift
/// let bulk = IP2LocationBulk(apiKey: "YOUR_API_KEY")
/// let result = try await bulk.lookup(ips: ["8.8.8.8", "1.1.1.1"])
/// for (ip, info) in result.results ?? [:] {
///     print("\(ip) → \(info.countryName ?? "?")")
/// }
/// ```
public struct IP2LocationBulk: Sendable {

    /// The default Bulk API endpoint.
    public static let defaultBaseURL = URL(string: "https://bulk.ip2location.io/")!

    /// The API key.  Required for the Bulk API.
    public var apiKey: String?

    /// How `apiKey` is transmitted.  Defaults to `.queryParameter`.
    public var authStyle: IP2Location.AuthStyle

    /// The API endpoint.  Defaults to `IP2LocationBulk.defaultBaseURL`.
    public var baseURL: URL

    /// The transport used to perform requests.  Defaults to `URLSession.shared`.
    public var session: any IP2LocationNetworking

    /// Creates a new IP2Location Bulk API client.
    ///
    /// - Parameters:
    ///   - apiKey: Your IP2Location.io API key (required for bulk).
    ///   - authStyle: How the API key is transmitted.
    ///   - baseURL: API endpoint override (for testing or regional endpoints).
    ///   - session: Transport used to perform requests.
    public init(apiKey: String? = nil,
                authStyle: IP2Location.AuthStyle = .queryParameter,
                baseURL: URL = IP2LocationBulk.defaultBaseURL,
                session: any IP2LocationNetworking = URLSession.shared) {
        self.apiKey = apiKey
        self.authStyle = authStyle
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Bulk lookup (async / await)

    /// Looks up one or more IP addresses in a single request.
    ///
    /// - Parameters:
    ///   - ips: IPv4 or IPv6 addresses to look up (max 1,000 per the API limit).
    ///   - fields: Optional subset of response fields to return.  When `nil`,
    ///             all fields are returned.  See the Bulk API documentation for
    ///             the full list of field names.
    /// - Returns: A `IP2LocationBulkResult` containing a dictionary of
    ///            `IP2LocationResult` values keyed by IP address.
    /// - Throws: `IP2LocationError` on network or API failures.
    @discardableResult
    public func lookup(ips: [String], fields: [String]? = nil) async throws -> IP2LocationBulkResult {
        try await withCheckedThrowingContinuation { continuation in
            lookup(ips: ips, fields: fields) { result in
                switch result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Bulk lookup (completion handler)

    /// Looks up one or more IP addresses in a single request.
    ///
    /// - Parameters:
    ///   - ips: IPv4 or IPv6 addresses to look up (max 1,000 per the API limit).
    ///   - fields: Optional subset of response fields to return.
    ///   - completion: Invoked once with either the decoded result or an
    ///                 `IP2LocationError`.
    public func lookup(ips: [String],
                       fields: [String]? = nil,
                       completion: @escaping (Result<IP2LocationBulkResult, IP2LocationError>) -> Void) {
        let request: URLRequest
        do {
            request = try makeRequest(ips: ips, fields: fields)
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

    private func makeRequest(ips: [String], fields: [String]?) throws -> URLRequest {
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

        if let fields, !fields.isEmpty {
            items.append(URLQueryItem(name: "fields", value: fields.joined(separator: ",")))
        }

        components.queryItems = items.isEmpty ? nil : items
        guard let url = components.url else {
            throw IP2LocationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if authStyle == .bearerToken, let apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        // Body: JSON array of IP strings
        let bodyData = try JSONSerialization.data(withJSONObject: ips, options: [])
        request.httpBody = bodyData

        return request
    }

    /// Decodes a raw HTTP response into an `IP2LocationBulkResult`, translating
    /// API error payloads and unexpected status codes into `IP2LocationError`.
    internal static func handle(data: Data, response: URLResponse) throws -> IP2LocationBulkResult {
        guard let http = response as? HTTPURLResponse else {
            throw IP2LocationError.invalidResponse
        }
        let isSuccess = (200..<300).contains(http.statusCode)

        if let result = try? JSONDecoder().decode(IP2LocationBulkResult.self, from: data) {
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

// MARK: - Bulk result type

/// The result of a Bulk IP geolocation lookup.
///
/// The API returns either:
/// - A dictionary of `IP2LocationResult` values keyed by IP address, or
/// - An error envelope `{ "error": { "error_code": ..., "error_message": ... } }`.
///
/// This type decodes either shape and exposes the result through the
/// `results` or `error` property accordingly.
public struct IP2LocationBulkResult: Sendable, Equatable {
    /// The geolocation results, keyed by the IP address string.
    ///
    /// Populated when the API returns a successful response.
    public var results: [String: IP2LocationResult]?

    /// The API error envelope, populated when the API returns an error object.
    public var error: IP2LocationAPIError?

    public init() {}
}

extension IP2LocationBulkResult: Decodable {
    private struct _Key: CodingKey, Hashable {
        var stringValue: String
        var intValue: Int? { nil }
        init(_ string: String) { self.stringValue = string }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: _Key.self)

        // Check for the error envelope first.
        if let apiError = try container.decodeIfPresent(
            IP2LocationAPIError.self, forKey: _Key("error")
        ) {
            self.error = apiError
            self.results = nil
            return
        }

        // Decode every other key as an IP2LocationResult.
        var results = [String: IP2LocationResult]()
        for key in container.allKeys {
            guard key.stringValue != "error" else { continue }
            results[key.stringValue] = try container.decode(IP2LocationResult.self, forKey: key)
        }
        self.results = results.isEmpty ? nil : results
        self.error = nil
    }
}