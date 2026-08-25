import Foundation

/// Errors thrown by the IP2Location.io Lookup API client.
public enum IP2LocationError: Error {
    /// The request URL could not be constructed from the given configuration.
    case invalidURL

    /// The server returned a response that was not a valid HTTP response.
    case invalidResponse

    /// The response body could not be decoded into an `IP2LocationResult`.
    case decodingFailed

    /// The server returned a non-2xx HTTP status code with no decodable
    /// API error payload.
    case httpStatus(Int)

    /// The API returned an error object (e.g. invalid IP address).
    case apiError(code: Int, message: String)

    /// A networking error occurred while performing the request.
    case transport(Error)
}

extension IP2LocationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Unable to build a valid request URL."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .decodingFailed:
            return "The API response could not be decoded."
        case .httpStatus(let code):
            return "The API returned HTTP status code \(code)."
        case .apiError(let code, let message):
            return "IP2Location API error \(code): \(message)"
        case .transport(let error):
            return "Network request failed: \(error.localizedDescription)"
        }
    }
}

/// The error object returned by the IP2Location.io API.
///
/// Decoded from a payload shaped like:
/// ```json
/// { "error": { "error_code": 10001, "error_message": "Invalid IP address." } }
/// ```
public struct IP2LocationAPIError: Codable, Sendable, Equatable {
    /// Numeric API error code.
    public var errorCode: Int?
    /// Human-readable description of the error.
    public var errorMessage: String?

    // Documented API error codes.
    /// Invalid API key or insufficient query.
    public static let invalidAPIKey = 10000
    /// Invalid IP address.
    public static let invalidIPAddress = 10001
    /// Internal server error.
    public static let internalServerError = 10002
    /// Invalid language code.
    public static let invalidLanguageCode = 10003
    /// Translation is not available with the active plan.
    public static let translationNotAvailable = 10004

    // Bulk API error codes.
    /// Invalid API key or insufficient query (Bulk API).
    public static let bulkInvalidAPIKey = 401
    /// Internal server error (Bulk API).
    public static let bulkInternalServerError = 500

    public init() {}

    enum CodingKeys: String, CodingKey {
        case errorCode = "error_code"
        case errorMessage = "error_message"
    }
}
