import Foundation
import XCTest
@testable import IP2LocationSwift

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class IP2LocationBulkClientTests: XCTestCase {

    private let freeResponse: String = #"""
    {
        "8.8.8.8": {
            "ip": "8.8.8.8",
            "country_code": "US",
            "country_name": "United States of America",
            "region_name": "California",
            "city_name": "Mountain View",
            "latitude": 37.38605,
            "longitude": -122.08385,
            "zip_code": "94035",
            "time_zone": "-07:00",
            "asn": "15169",
            "as": "Google LLC",
            "is_proxy": false
        }
    }
    """#

    private func makeResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: IP2LocationBulk.defaultBaseURL,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
    }

    // MARK: - Decoding tests

    func testDecodesBulkResponse() throws {
        let json = #"""
        {
            "1.1.1.1": {
                "country_code": "AU",
                "country_name": "Australia",
                "region_name": "Queensland",
                "city_name": "Brisbane",
                "latitude": -27.46754,
                "longitude": 153.02809,
                "zip_code": "4000",
                "time_zone": "+10:00",
                "asn": "13335",
                "as": "CloudFlare Inc",
                "is_proxy": false
            },
            "2.2.2.2": {
                "country_code": "US",
                "country_name": "United States of America",
                "region_name": "Virginia",
                "city_name": "Redwood",
                "latitude": 37.005847,
                "longitude": -79.770089,
                "zip_code": "24146",
                "time_zone": "-04:00",
                "asn": "15519",
                "as": "Oracle Svenska AB",
                "is_proxy": false
            }
        }
        """#

        let result = try JSONDecoder().decode(IP2LocationBulkResult.self, from: Data(json.utf8))

        XCTAssertNil(result.error)
        let results = try XCTUnwrap(result.results)
        XCTAssertEqual(results.count, 2)

        let ip1 = try XCTUnwrap(results["1.1.1.1"])
        XCTAssertEqual(ip1.countryCode, "AU")
        XCTAssertEqual(ip1.countryName, "Australia")
        XCTAssertEqual(ip1.cityName, "Brisbane")

        let ip2 = try XCTUnwrap(results["2.2.2.2"])
        XCTAssertEqual(ip2.countryCode, "US")
        XCTAssertEqual(ip2.countryName, "United States of America")
        XCTAssertEqual(ip2.cityName, "Redwood")
    }

    func testDecodesBulkErrorResponse() throws {
        let json = #"""
        {
            "error": {
                "error_code": 401,
                "error_message": "Invalid API key or insufficient query."
            }
        }
        """#

        let result = try JSONDecoder().decode(IP2LocationBulkResult.self, from: Data(json.utf8))

        XCTAssertNil(result.results)
        XCTAssertEqual(result.error?.errorCode, 401)
        XCTAssertEqual(result.error?.errorMessage, "Invalid API key or insufficient query.")
    }

    func testDecodesBulkResponseWithFullObjects() throws {
        let json = #"""
        {
            "1.1.1.1": {
                "country_code": "AU",
                "country_name": "Australia",
                "continent": {
                    "name": "Oceania",
                    "code": "OC",
                    "hemisphere": ["south", "east"],
                    "translation": { "lang": "en", "value": "Oceania" }
                },
                "country": {
                    "name": "Australia",
                    "alpha3_code": "AUS",
                    "numeric_code": 36,
                    "currency": { "code": "AUD", "name": "Australian Dollar", "symbol": "$" },
                    "language": { "code": "EN", "name": "English" }
                },
                "time_zone_info": {
                    "olson": "Australia/Brisbane",
                    "current_time": "2026-08-05T16:39:39+10:00",
                    "gmt_offset": 36000,
                    "is_dst": false,
                    "abbreviation": "AEST"
                },
                "proxy": {
                    "last_seen": 1,
                    "proxy_type": "DCH",
                    "is_vpn": false,
                    "is_data_center": true
                },
                "is_proxy": false,
                "fraud_score": 0
            }
        }
        """#

        let result = try JSONDecoder().decode(IP2LocationBulkResult.self, from: Data(json.utf8))
        let r = try XCTUnwrap(result.results?["1.1.1.1"])

        XCTAssertEqual(r.continent?.name, "Oceania")
        XCTAssertEqual(r.continent?.code, "OC")
        XCTAssertEqual(r.continent?.hemisphere, ["south", "east"])
        XCTAssertEqual(r.country?.alpha3Code, "AUS")
        XCTAssertEqual(r.country?.currency?.code, "AUD")
        XCTAssertEqual(r.timeZoneInfo?.olson, "Australia/Brisbane")
        XCTAssertEqual(r.timeZoneInfo?.gmtOffset, 36000)
        XCTAssertEqual(r.proxy?.proxyType, "DCH")
        XCTAssertEqual(r.proxy?.isDataCenter, true)
        XCTAssertEqual(r.fraudScore, 0)
    }

    // MARK: - Client request construction

    func testBulkLookupSendsPOSTWithJSONBody() async throws {
        let mock = MockNetworking { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Content-Type"),
                "application/json"
            )
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Accept"),
                "application/json"
            )

            // Verify the body is a JSON array of IPs
            let body = try XCTUnwrap(request.httpBody)
            let ips = try JSONSerialization.jsonObject(with: body, options: []) as? [String]
            XCTAssertEqual(ips, ["8.8.8.8", "1.1.1.1"])

            let data = #"{"8.8.8.8":{"country_code":"US"},"1.1.1.1":{"country_code":"AU"}}"#.data(using: .utf8)!
            return (data, self.makeResponse(statusCode: 200))
        }

        let client = IP2LocationBulk(apiKey: "test-key", session: mock)
        let result = try await client.lookup(ips: ["8.8.8.8", "1.1.1.1"])

        XCTAssertEqual(result.results?.count, 2)
        XCTAssertEqual(result.results?["8.8.8.8"]?.countryCode, "US")
        XCTAssertEqual(result.results?["1.1.1.1"]?.countryCode, "AU")
    }

    func testBulkLookupWithQueryParamAuth() async throws {
        let mock = MockNetworking { request in
            let url = try XCTUnwrap(request.url)
            let query = try XCTUnwrap(
                URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            )
            let params = Dictionary(uniqueKeysWithValues: query.map { ($0.name, $0.value ?? "") })
            XCTAssertEqual(params["key"], "bulk-key")
            XCTAssertNil(params["Authorization"])

            let data = #"{"8.8.8.8":{"country_code":"US"}}"#.data(using: .utf8)!
            return (data, self.makeResponse(statusCode: 200))
        }

        let client = IP2LocationBulk(apiKey: "bulk-key", session: mock)
        _ = try await client.lookup(ips: ["8.8.8.8"])
    }

    func testBulkLookupWithBearerAuth() async throws {
        let mock = MockNetworking { request in
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Authorization"),
                "Bearer bulk-key"
            )
            let url = try XCTUnwrap(request.url)
            let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            XCTAssertFalse(query?.contains { $0.name == "key" } ?? true)

            let data = #"{"8.8.8.8":{"country_code":"US"}}"#.data(using: .utf8)!
            return (data, self.makeResponse(statusCode: 200))
        }

        let client = IP2LocationBulk(apiKey: "bulk-key", authStyle: .bearerToken, session: mock)
        _ = try await client.lookup(ips: ["8.8.8.8"])
    }

    func testBulkLookupWithFieldsParameter() async throws {
        let mock = MockNetworking { request in
            let url = try XCTUnwrap(request.url)
            let query = try XCTUnwrap(
                URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
            )
            let fields = query.first { $0.name == "fields" }?.value
            XCTAssertEqual(fields, "country_code,country_name,isp")

            let data = #"{"8.8.8.8":{"country_code":"US","country_name":"United States of America","isp":"Google LLC"}}"#.data(using: .utf8)!
            return (data, self.makeResponse(statusCode: 200))
        }

        let client = IP2LocationBulk(apiKey: "k", session: mock)
        let result = try await client.lookup(ips: ["8.8.8.8"], fields: ["country_code", "country_name", "isp"])
        let r = try XCTUnwrap(result.results?["8.8.8.8"])
        XCTAssertEqual(r.countryCode, "US")
        XCTAssertEqual(r.countryName, "United States of America")
        XCTAssertEqual(r.isp, "Google LLC")
    }

    // MARK: - Error handling

    func testBulkAPIDefinedErrorIsThrown() async {
        let mock = MockNetworking { _ in
            let data = #"{"error":{"error_code":401,"error_message":"Invalid API key or insufficient query."}}"#.data(using: .utf8)!
            return (data, self.makeResponse(statusCode: 401))
        }

        let client = IP2LocationBulk(apiKey: "bad-key", session: mock)
        do {
            _ = try await client.lookup(ips: ["8.8.8.8"])
            XCTFail("Expected apiError to be thrown")
        } catch let error as IP2LocationError {
            guard case .apiError(let code, let message) = error else {
                return XCTFail("Expected .apiError, got \(error)")
            }
            XCTAssertEqual(code, 401)
            XCTAssertEqual(message, "Invalid API key or insufficient query.")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Completion handler

    func testBulkCompletionHandler() {
        let mock = MockNetworking { _ in
            let data = #"{"8.8.8.8":{"country_code":"US","city_name":"Mountain View"}}"#.data(using: .utf8)!
            return (data, self.makeResponse(statusCode: 200))
        }
        let client = IP2LocationBulk(apiKey: "k", session: mock)
        var received: Result<IP2LocationBulkResult, IP2LocationError>?

        client.lookup(ips: ["8.8.8.8"]) { received = $0 }

        guard case .success(let result)? = received else {
            return XCTFail("Expected success, got \(String(describing: received))")
        }
        XCTAssertEqual(result.results?["8.8.8.8"]?.cityName, "Mountain View")
    }

    // MARK: - Bulk error code constants

    func testBulkErrorCodeConstants() {
        XCTAssertEqual(IP2LocationAPIError.bulkInvalidAPIKey, 401)
        XCTAssertEqual(IP2LocationAPIError.bulkInternalServerError, 500)
    }
}