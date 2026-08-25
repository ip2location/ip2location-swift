import XCTest
@testable import IP2LocationSwift

final class IP2LocationResultDecodingTests: XCTestCase {

    private func decode(_ json: String) throws -> IP2LocationResult {
        try JSONDecoder().decode(IP2LocationResult.self, from: Data(json.utf8))
    }

    // MARK: - Free plan

    func testDecodesFreePlanResponse() throws {
        let json = #"""
        {
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
        """#

        let result = try decode(json)

        XCTAssertEqual(result.ip, "8.8.8.8")
        XCTAssertEqual(result.countryCode, "US")
        XCTAssertEqual(result.countryName, "United States of America")
        XCTAssertEqual(result.regionName, "California")
        XCTAssertEqual(result.cityName, "Mountain View")
        XCTAssertEqual(result.latitude, 37.38605)
        XCTAssertEqual(result.longitude, -122.08385)
        XCTAssertEqual(result.zipCode, "94035")
        XCTAssertEqual(result.timeZone, "-07:00")
        XCTAssertEqual(result.asn, "15169")
        XCTAssertEqual(result.asName, "Google LLC")
        XCTAssertEqual(result.isProxy, false)

        // Fields outside the Free plan must be nil.
        XCTAssertNil(result.timeZoneInfo)
        XCTAssertNil(result.proxy)
        XCTAssertNil(result.country)
    }

    // MARK: - Security plan (superset)

    func testDecodesSecurityPlanResponse() throws {
        let json = #"""
        {
            "ip": "8.8.8.8",
            "country_code": "US",
            "country_name": "United States of America",
            "region_name": "California",
            "district": "Santa Clara County",
            "city_name": "Mountain View",
            "latitude": 37.38605,
            "longitude": -122.08385,
            "zip_code": "94035",
            "time_zone": "-07:00",
            "asn": "15169",
            "as": "Google LLC",
            "as_info": {
                "as_number": "15169",
                "as_name": "Google LLC",
                "as_domain": "google.com",
                "as_usage_type": "DCH",
                "as_cidr": "8.8.8.0/24"
            },
            "isp": "Google LLC",
            "domain": "google.com",
            "net_speed": "T1",
            "idd_code": "1",
            "area_code": "650",
            "weather_station_code": "USCA0746",
            "weather_station_name": "Mountain View",
            "mcc": "-",
            "mnc": "-",
            "mobile_brand": "-",
            "elevation": 32,
            "usage_type": "DCH",
            "address_type": "Anycast",
            "ads_category": "IAB19-11",
            "ads_category_name": "Data Centers",
            "continent": {
                "name": "North America",
                "code": "NA",
                "hemisphere": ["north", "west"],
                "translation": { "lang": "ko", "value": "북아메리카" }
            },
            "country": {
                "name": "United States of America",
                "alpha3_code": "USA",
                "numeric_code": 840,
                "demonym": "Americans",
                "flag": "https://cdn.ip2location.io/assets/img/flags/us.png",
                "capital": "Washington, D.C.",
                "total_area": 9826675,
                "population": 339665118,
                "currency": { "code": "USD", "name": "United States Dollar", "symbol": "$" },
                "language": { "code": "EN", "name": "English" },
                "tld": "us",
                "translation": { "lang": "ko", "value": "미국" }
            },
            "region": {
                "name": "California",
                "code": "US-CA",
                "translation": { "lang": "ko", "value": "캘리포니아주" }
            },
            "city": {
                "name": "Mountain View",
                "translation": { "lang": null, "value": null }
            },
            "time_zone_info": {
                "olson": "America/Los_Angeles",
                "current_time": "2025-07-16T19:06:49-07:00",
                "gmt_offset": -25200,
                "is_dst": true,
                "abbreviation": "PDT",
                "dst_start_date": "2025-03-09",
                "dst_end_date": "2025-11-02",
                "sunrise": "06:00",
                "sunset": "20:29"
            },
            "geotargeting": {
                "metro": "807"
            },
            "is_proxy": false,
            "fraud_score": 0,
            "proxy": {
                "last_seen": 13,
                "proxy_type": "DCH",
                "threat": "-",
                "provider": "-",
                "is_vpn": false,
                "is_tor": false,
                "is_data_center": true,
                "is_public_proxy": false,
                "is_web_proxy": false,
                "is_web_crawler": false,
                "is_ai_crawler": false,
                "is_residential_proxy": false,
                "is_consumer_privacy_network": false,
                "is_enterprise_private_network": false,
                "is_spammer": false,
                "is_scanner": false,
                "is_botnet": false,
                "is_bogon": false
            }
        }
        """#

        let result = try decode(json)

        // Top-level fields
        XCTAssertEqual(result.district, "Santa Clara County")
        XCTAssertEqual(result.isp, "Google LLC")
        XCTAssertEqual(result.netSpeed, "T1")
        XCTAssertEqual(result.usageType, "DCH")
        XCTAssertEqual(result.addressType, "Anycast")
        XCTAssertEqual(result.adsCategory, "IAB19-11")
        XCTAssertEqual(result.adsCategoryName, "Data Centers")
        XCTAssertEqual(result.fraudScore, 0)
        XCTAssertEqual(result.isProxy, false)

        // AS info
        XCTAssertEqual(result.asInfo?.asNumber, "15169")
        XCTAssertEqual(result.asInfo?.asName, "Google LLC")
        XCTAssertEqual(result.asInfo?.asDomain, "google.com")
        XCTAssertEqual(result.asInfo?.asCidr, "8.8.8.0/24")

        // Continent
        XCTAssertEqual(result.continent?.name, "North America")
        XCTAssertEqual(result.continent?.code, "NA")
        XCTAssertEqual(result.continent?.hemisphere, ["north", "west"])
        XCTAssertEqual(result.continent?.translation?.lang, "ko")
        XCTAssertEqual(result.continent?.translation?.value, "북아메리카")

        // Country (including nested currency & language)
        XCTAssertEqual(result.country?.alpha3Code, "USA")
        XCTAssertEqual(result.country?.numericCode, 840)
        XCTAssertEqual(result.country?.totalArea, 9826675)
        XCTAssertEqual(result.country?.population, 339665118)
        XCTAssertEqual(result.country?.currency?.code, "USD")
        XCTAssertEqual(result.country?.currency?.symbol, "$")
        XCTAssertEqual(result.country?.language?.name, "English")
        XCTAssertEqual(result.country?.tld, "us")

        // Region / city / translation
        XCTAssertEqual(result.region?.code, "US-CA")
        XCTAssertEqual(result.city?.name, "Mountain View")
        // null values decode to nil optionals.
        XCTAssertNil(result.city?.translation?.lang)
        XCTAssertNil(result.city?.translation?.value)

        // Time zone info
        XCTAssertEqual(result.timeZoneInfo?.olson, "America/Los_Angeles")
        XCTAssertEqual(result.timeZoneInfo?.gmtOffset, -25200)
        XCTAssertEqual(result.timeZoneInfo?.isDst, true)
        XCTAssertEqual(result.timeZoneInfo?.abbreviation, "PDT")
        XCTAssertEqual(result.timeZoneInfo?.sunrise, "06:00")
        XCTAssertEqual(result.timeZoneInfo?.sunset, "20:29")

        // Geotargeting
        XCTAssertEqual(result.geotargeting?.metro, "807")

        // Proxy object
        XCTAssertEqual(result.proxy?.lastSeen, 13)
        XCTAssertEqual(result.proxy?.proxyType, "DCH")
        XCTAssertEqual(result.proxy?.isDataCenter, true)
        XCTAssertEqual(result.proxy?.isVPN, false)
        XCTAssertEqual(result.proxy?.isAICrawler, false)
    }

    // MARK: - Error envelope

    func testDecodesAPIErrorEnvelope() throws {
        let json = #"""
        {
            "error": {
                "error_code": 10001,
                "error_message": "Invalid IP address."
            }
        }
        """#

        let result = try decode(json)

        XCTAssertEqual(result.ip, nil)
        XCTAssertEqual(result.error?.errorCode, 10001)
        XCTAssertEqual(result.error?.errorMessage, "Invalid IP address.")
    }

    func testDocumentedErrorCodeConstants() {
        XCTAssertEqual(IP2LocationAPIError.invalidAPIKey, 10000)
        XCTAssertEqual(IP2LocationAPIError.invalidIPAddress, 10001)
        XCTAssertEqual(IP2LocationAPIError.internalServerError, 10002)
        XCTAssertEqual(IP2LocationAPIError.invalidLanguageCode, 10003)
        XCTAssertEqual(IP2LocationAPIError.translationNotAvailable, 10004)
    }
}
