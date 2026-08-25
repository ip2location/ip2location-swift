# IP2LocationSwift

A lightweight, dependency-free Swift SDK for the [IP2Location.io](https://www.ip2location.io/ip2location-documentation) IP geolocation Lookup API. It queries IP addresses (IPv4 & IPv6) in real time and decodes the response into typed Swift models.

- Async/await and completion-handler APIs
- Zero dependencies
- Keyless and API-key lookups
- Full response model across all plans (Free / Starter / Plus / Security)
- Localized names via the `lang` parameter (Plus / Security Plans only)



## Installation

### Swift Package Manager

Add the package to your `Package.swift`:

```swift
.package(url: "https://github.com/ip2location/ip2loction-switf.git", from: "1.0.0")
```

or via Xcode: **File ▸ Add Packages…** ▸ paste the repository URL.



## Test

```sh
# Clone this repository
git clone https://github.com/ip2location/ip2loction-switf.git

# Go into SDK directory
cd ip2location-swift

# Build the binary
swift build

# Run tests
swift test
```




## Quick Start

```swift
import IP2LocationSwift

let client = IP2Location(apiKey: "YOUR_API_KEY")
```



### Async / await

```swift
do {
    let result = try await client.lookup(ip: "8.8.8.8")
    print(result.countryName ?? "Unknown")   // United States of America
    print(result.cityName ?? "Unknown")      // Mountain View
} catch {
    print("Lookup failed: \(error.localizedDescription)")
}
```



### Completion handler

```swift
client.lookup(ip: "8.8.8.8") {
    result in
        switch result {
            case .success(let info):
                print(info.isp ?? "Unknown ISP")
            case .failure(let error):
                print("Lookup failed: \(error.localizedDescription)")
        }
}
```



### Keyless lookup

The API works without a key (up to 1,000 queries/day). Omit the `apiKey` and leave `ip` as `nil` to resolve the requester's own IP:

```swift
let client = IP2Location()
let myInfo = try await client.lookup()
```



### Localized names (Plus / Security plans)

```swift
let result = try await client.lookup(ip: "8.8.8.8", lang: .korean)
print(result.country?.translation?.value)   // 미국
print(result.continent?.translation?.value) // 북아메리카
```

A default language can be set on the client instead:

```swift
let client = IP2Location(apiKey: "YOUR_API_KEY", lang: .japanese)
```



### Authentication styles

By default the API key is sent as a `key` URL query parameter. It can also be sent as a Bearer token:

```swift
let client = IP2Location(apiKey: "YOUR_API_KEY", authStyle: .bearerToken)
```



### Bulk lookup

The Bulk API processes up to 1,000 IPv4 & IPv6 addresses in a single POST request. It requires a paid plan.

```swift
let bulk = IP2LocationBulk(apiKey: "YOUR_API_KEY")
let result = try await bulk.lookup(ips: ["8.8.8.8", "1.1.1.1"])
for (ip, info) in result.results ?? [:] {
    print("\(ip) → \(info.countryName ?? "?")")
}
```

Optionally restrict which fields are returned:

```swift
let result = try await bulk.lookup(
    ips: ["8.8.8.8", "1.1.1.1"],
    fields: ["country_code", "country_name", "isp"]
)
```



## API

### `IP2Location`

```swift
IP2Location(
    apiKey: String? = nil,
    authStyle: AuthStyle = .queryParameter,   // .queryParameter | .bearerToken
    lang: IP2Language? = nil,
    baseURL: URL = .init(string: "https://api.ip2location.io/")!,
    session: any IP2LocationNetworking = URLSession.shared
)

func lookup(ip: String? = nil, lang: IP2Language? = nil) async throws -> IP2LocationResult
func lookup(ip: String? = nil, lang: IP2Language? = nil,
            completion: @escaping (Result<IP2LocationResult, IP2LocationError>) -> Void)
```

| Parameter | Description |
| --- | --- |
| `ip` | IPv4 or IPv6 address to look up. When `nil`, the API resolves the requester's own IP. |
| `lang` | ISO 639-1 translation language (Plus/Security plans only). Supported: `arabic`, `czech`, `danish`, `german`, `english`, `spanish`, `estonian`, `finnish`, `french`, `irish`, `italian`, `japanese`, `korean`, `malay`, `dutch`, `portuguese`, `russian`, `swedish`, `turkish`, `vietnamese`, `chineseSimplified`, `chineseTraditional`. |



### `IP2LocationBulk`

```swift
IP2LocationBulk(
    apiKey: String? = nil,
    authStyle: IP2Location.AuthStyle = .queryParameter,
    baseURL: URL = .init(string: "https://bulk.ip2location.io/")!,
    session: any IP2LocationNetworking = URLSession.shared
)

func lookup(ips: [String], fields: [String]? = nil) async throws -> IP2LocationBulkResult
func lookup(ips: [String], fields: [String]? = nil,
            completion: @escaping (Result<IP2LocationBulkResult, IP2LocationError>) -> Void)
```

| Parameter | Description |
| --- | --- |
| `ips` | Array of IPv4 or IPv6 addresses to look up (max 1,000). |
| `fields` | Optional subset of response fields (e.g. `["country_code", "isp"]`). When `nil`, all fields are returned. |

The response type `IP2LocationBulkResult` has two properties:

- `results: [String: IP2LocationResult]?` — geolocation data keyed by IP address.
- `error: IP2LocationAPIError?` — populated when the API returns an error object.

> **Note:** The Bulk API requires a paid plan. The `lang` parameter is not supported on the bulk endpoint.



### Response model

`IP2LocationResult` mirrors the API's JSON. Every property is optional because the fields present depend on the plan:

| Group | Swift properties (JSON key) |
| --- | --- |
| Basic | `ip`, `countryCode`, `countryName`, `regionName`, `cityName`, `latitude`, `longitude`, `zipCode`, `timeZone`, `asn`, `asName` (`as`), `isProxy` |
| Advanced (Starter) | `isp`, `domain`, `netSpeed`, `iddCode`, `areaCode`, `weatherStationCode`, `weatherStationName`, `elevation`, `usageType` |
| Mobile & address (Plus) | `mcc`, `mnc`, `mobileBrand`, `addressType` |
| Objects (Plus) | `continent`, `country`, `region`, `city`, `timeZoneInfo`, `geotargeting` |
| Security | `district`, `asInfo`, `adsCategory`, `adsCategoryName`, `fraudScore`, `proxy` |

Nested objects (`IP2LocationResult.Country`, `.Region`, `.Continent`, `.TimeZoneInfo`, `.ProxyInfo`, `.ASInfo`, etc.) expose the documented fields.

> [!NOTE]
> The top-level JSON field `as` is a reserved keyword in Swift, so it is exposed as `asName`.



### Errors

`IP2LocationError` is thrown for network and API failures:

```swift
case .invalidURL
case .invalidResponse
case .decodingFailed
case .httpStatus(Int)
case .apiError(code: Int, message: String)
case .transport(Error)
```

Documented API error codes are exposed as constants on `IP2LocationAPIError`:

| Constant | Code | Meaning |
| --- | --- | --- |
| `invalidAPIKey` | 10000 | Invalid API key or insufficient query. |
| `invalidIPAddress` | 10001 | Invalid IP address. |
| `internalServerError` | 10002 | Internal server error. |
| `invalidLanguageCode` | 10003 | Invalid language code. |
| `translationNotAvailable` | 10004 | Translation not available with your plan. |



## Response Format

Only the JSON response format is supported (the API's default). The `format` parameter and the XML format are intentionally not exposed — JSON is the natural choice for Swift. The request is always sent as `GET`.



## License

MIT — see [LICENSE](LICENSE).
