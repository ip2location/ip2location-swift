import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import XCTest
@testable import IP2LocationSwift

/// A transport that serves canned responses and records the last request,
/// so tests never touch the network.
final class MockNetworking: IP2LocationNetworking, @unchecked Sendable {
    private let handler: (URLRequest) throws -> (Data, HTTPURLResponse)
    private(set) var lastRequest: URLRequest?

    init(handler: @escaping (URLRequest) throws -> (Data, HTTPURLResponse)) {
        self.handler = handler
    }

    func perform(_ request: URLRequest,
                 completion: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) {
        lastRequest = request
        do {
            let (data, response) = try handler(request)
            completion(data, response, nil)
        } catch {
            completion(nil, nil, error)
        }
    }
}

final class IP2LocationClientTests: XCTestCase {

    private func makeResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: IP2Location.defaultBaseURL,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
    }

    // MARK: - Request construction

    func testQueryParameterAuthAndParameters() async throws {
        let mock = MockNetworking { request in
            XCTAssertEqual(request.httpMethod, "GET")
            let query = try XCTUnwrap(
                URLComponents(url: XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?.queryItems
            )
            let params = Dictionary(uniqueKeysWithValues: query.map { ($0.name, $0.value ?? "") })
            XCTAssertEqual(params["key"], "test-key")
            XCTAssertEqual(params["ip"], "8.8.8.8")
            XCTAssertEqual(params["lang"], "ja")

            let data = #"{"ip":"8.8.8.8","country_code":"US"}"#.data(using: .utf8)!
            return (data, self.makeResponse(statusCode: 200))
        }

        let client = IP2Location(apiKey: "test-key", lang: .japanese, session: mock)
        let result = try await client.lookup(ip: "8.8.8.8")

        XCTAssertEqual(result.ip, "8.8.8.8")
        XCTAssertEqual(result.countryCode, "US")
    }

    func testBearerTokenAuth() async throws {
        let mock = MockNetworking { request in
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Authorization"),
                "Bearer test-key"
            )
            let query = URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?.queryItems
            XCTAssertFalse(query?.contains { $0.name == "key" } ?? true)

            let data = #"{"ip":"8.8.8.8","country_code":"US"}"#.data(using: .utf8)!
            return (data, self.makeResponse(statusCode: 200))
        }

        let client = IP2Location(apiKey: "test-key", authStyle: .bearerToken, session: mock)
        _ = try await client.lookup(ip: "8.8.8.8")
    }

    func testKeylessLookupSendsNoKey() async throws {
        let mock = MockNetworking { request in
            let query = URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?.queryItems
            XCTAssertFalse(query?.contains { $0.name == "key" } ?? true)

            let data = #"{"ip":"8.8.8.8"}"#.data(using: .utf8)!
            return (data, self.makeResponse(statusCode: 200))
        }

        let client = IP2Location(session: mock)
        _ = try await client.lookup(ip: "8.8.8.8")
    }

    func testIPv6AddressIsEncoded() async throws {
        let mock = MockNetworking { request in
            let query = URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)?.queryItems
            let ip = query?.first { $0.name == "ip" }?.value
            XCTAssertEqual(ip, "2001:4860:4860::8888")

            let data = #"{"ip":"2001:4860:4860::8888"}"#.data(using: .utf8)!
            return (data, self.makeResponse(statusCode: 200))
        }

        let client = IP2Location(session: mock)
        let result = try await client.lookup(ip: "2001:4860:4860::8888")
        XCTAssertEqual(result.ip, "2001:4860:4860::8888")
    }

    // MARK: - Error handling

    func testAPIDefinedErrorIsThrownEvenWith200Status() async {
        let mock = MockNetworking { _ in
            let data = #"{"error":{"error_code":10001,"error_message":"Invalid IP address."}}"#.data(using: .utf8)!
            return (data, self.makeResponse(statusCode: 200))
        }

        let client = IP2Location(apiKey: "k", session: mock)
        do {
            _ = try await client.lookup(ip: "999.999.999.999")
            XCTFail("Expected apiError to be thrown")
        } catch let error as IP2LocationError {
            guard case .apiError(let code, let message) = error else {
                return XCTFail("Expected .apiError, got \(error)")
            }
            XCTAssertEqual(code, 10001)
            XCTAssertEqual(message, "Invalid IP address.")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testHTTPErrorStatusIsThrown() async {
        let mock = MockNetworking { _ in
            (Data("oops".utf8), self.makeResponse(statusCode: 500))
        }

        let client = IP2Location(session: mock)
        do {
            _ = try await client.lookup(ip: "8.8.8.8")
            XCTFail("Expected httpStatus to be thrown")
        } catch let error as IP2LocationError {
            guard case .httpStatus(let code) = error else {
                return XCTFail("Expected .httpStatus, got \(error)")
            }
            XCTAssertEqual(code, 500)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testInvalidJSONOnSuccessThrowsDecodingFailed() async {
        let mock = MockNetworking { _ in
            (Data("not-json".utf8), self.makeResponse(statusCode: 200))
        }

        let client = IP2Location(session: mock)
        do {
            _ = try await client.lookup(ip: "8.8.8.8")
            XCTFail("Expected decodingFailed to be thrown")
        } catch let error as IP2LocationError {
            guard case .decodingFailed = error else {
                return XCTFail("Expected .decodingFailed, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Completion handler API

    func testCompletionHandlerVariantDeliversResult() {
        let mock = MockNetworking { _ in
            let data = #"{"ip":"8.8.8.8","country_code":"US","city_name":"Mountain View"}"#.data(using: .utf8)!
            return (data, self.makeResponse(statusCode: 200))
        }

        let client = IP2Location(session: mock)
        var received: Result<IP2LocationResult, IP2LocationError>?

        client.lookup(ip: "8.8.8.8") { received = $0 }

        switch received {
        case .success(let result)?:
            XCTAssertEqual(result.countryCode, "US")
            XCTAssertEqual(result.cityName, "Mountain View")
        case .failure(let error)?:
            XCTFail("Unexpected failure: \(error)")
        case nil:
            XCTFail("Completion handler was never called")
        }
    }

    func testCompletionHandlerVariantDeliversAPIError() {
        let mock = MockNetworking { _ in
            let data = #"{"error":{"error_code":10000,"error_message":"Invalid API key or insufficient query."}}"#.data(using: .utf8)!
            return (data, self.makeResponse(statusCode: 401))
        }

        let client = IP2Location(apiKey: "bad-key", session: mock)
        var received: Result<IP2LocationResult, IP2LocationError>?

        client.lookup(ip: "8.8.8.8") { received = $0 }

        guard case .failure(let error)? = received else {
            return XCTFail("Expected failure, got \(String(describing: received))")
        }
        guard case .apiError(let code, _) = error else {
            return XCTFail("Expected .apiError, got \(error)")
        }
        XCTAssertEqual(code, 10000)
    }
}
