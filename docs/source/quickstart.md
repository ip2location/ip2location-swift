# Quickstart

## Requirements

- Swift 5.7 or later
- iOS 13 or later, macOS 10.15 or later, tvOS 13 or later, watchOS 6 or later
- On Linux, the Swift toolchain from [swift.org](https://www.swift.org/install/linux/) or Debian 13's `swiftlang` package

## Installation

### Swift Package Manager

Add the package to your `Package.swift`:

```swift
.package(url: "https://github.com/ip2location/ip2location-swift.git", from: "1.0.0")
```

Then add `IP2LocationSwift` to your target's dependencies:

```swift
.target(
    name: "MyApp",
    dependencies: ["IP2LocationSwift"]
)
```

Or via Xcode: **File ▸ Add Packages…** and paste the repository URL.

## API key

The API works without a key for up to 1,000 queries per day. To go beyond that, sign up for a free API key at <https://www.ip2location.io/sign-up>.

:::{note}
The bulk endpoint requires a paid plan. Keyless access is not available for bulk lookups.
:::

## Sample Codes

### Query geolocation information for an IP address

Create a client with your API key and call `lookup()`:

```swift
import IP2LocationSwift

let client = IP2Location(apiKey: "YOUR_API_KEY")

do {
    let result = try await client.lookup(ip: "8.8.8.8")

    print(result.ip ?? "")            // 8.8.8.8
    print(result.countryCode ?? "")   // US
    print(result.countryName ?? "")   // United States of America
    print(result.regionName ?? "")    // California
    print(result.cityName ?? "")      // Mountain View
    print(result.latitude ?? 0)       // 37.38605
    print(result.longitude ?? 0)      // -122.08385
    print(result.zipCode ?? "")       // 94035
    print(result.timeZone ?? "")      // -07:00
    print(result.asn ?? "")           // 15169
    print(result.asName ?? "")        // Google LLC
    print(result.isProxy ?? false)    // false
} catch {
    print("Lookup failed: \(error.localizedDescription)")
}
```

Every property is optional, because the fields returned depend on your plan.

### Completion handler

The same call is available with a completion handler:

```swift
client.lookup(ip: "8.8.8.8") { result in
    switch result {
    case .success(let info):
        print(info.cityName ?? "Unknown")
    case .failure(let error):
        print("Lookup failed: \(error.localizedDescription)")
    }
}
```

### Query your own IP address

Omit both the API key and the IP address to resolve the requester's IP:

```swift
let client = IP2Location()
let myInfo = try await client.lookup()
```

### IPv6 address

IPv6 works exactly the same way:

```swift
let result = try await client.lookup(ip: "2001:4860:4860::8888")
```

### Localized names

Pass a language to translate the continent, country, region and city names. Translations are only available on the Plus and Security plans.

```swift
let result = try await client.lookup(ip: "8.8.8.8", lang: .korean)
print(result.country?.translation?.value ?? "")    // 미국
print(result.continent?.translation?.value ?? "")  // 북아메리카
```

A default language can be set on the client instead:

```swift
let client = IP2Location(apiKey: "YOUR_API_KEY", lang: .japanese)
```

### Authentication with a bearer token

By default the API key is sent as a `key` URL query parameter. It can also be sent in the `Authorization` header:

```swift
let client = IP2Location(apiKey: "YOUR_API_KEY", authStyle: .bearerToken)
```

### Bulk lookup

The bulk endpoint processes up to 1,000 IPv4 and IPv6 addresses in a single POST request and returns the results keyed by IP address.

```swift
let bulk = IP2LocationBulk(apiKey: "YOUR_API_KEY")

do {
    let result = try await bulk.lookup(ips: ["8.8.8.8", "1.1.1.1"])

    for (ip, info) in result.results ?? [:] {
        print("\(ip): \(info.countryName ?? "?") / \(info.cityName ?? "?")")
    }
} catch {
    print("Bulk lookup failed: \(error.localizedDescription)")
}
```

Limit the response to the fields you need:

```swift
let result = try await bulk.lookup(
    ips: ["8.8.8.8", "1.1.1.1"],
    fields: ["country_code", "country_name", "isp"]
)
```

:::{note}
The `lang` parameter is not supported on the bulk endpoint.
:::

### Handling errors

Every failure is reported as an `IP2LocationError`:

```swift
do {
    _ = try await client.lookup(ip: "999.999.999.999")
} catch IP2LocationError.apiError(let code, let message) {
    print("API error \(code): \(message)")   // API error 10001: Invalid IP address.
} catch {
    print("Request failed: \(error.localizedDescription)")
}
```

### Running the example

The package ships a runnable example that exercises every feature:

```
export IP2LOCATION_API_KEY="YOUR_API_KEY"
swift run IP2LocationExample
```

Pass an IP address as an argument to look up a specific address:

```
swift run IP2LocationExample 8.8.8.8
```

## Testing

The test suite is fully mocked and needs no API key or network access:

```
swift test
```
