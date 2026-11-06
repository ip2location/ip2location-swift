# IP2Location Swift API

## IP2Location Class

```swift
IP2Location(apiKey: String? = nil,
            authStyle: AuthStyle = .queryParameter,
            lang: IP2Language? = nil,
            baseURL: URL = URL(string: "https://api.ip2location.io/")!,
            session: any IP2LocationNetworking = URLSession.shared)
```

Creates a client for the IP2Location.io single lookup endpoint.

| Parameter | Description |
| --- | --- |
| `apiKey` | (Optional) Your API key. When `nil`, requests are sent keyless. |
| `authStyle` | (Optional) How the API key is transmitted: `.queryParameter` or `.bearerToken`. Defaults to `.queryParameter`. |
| `lang` | (Optional) Default translation language. Used when a call does not pass its own. |
| `baseURL` | (Optional) API endpoint. Defaults to `https://api.ip2location.io/`. |
| `session` | (Optional) Transport used for requests. Defaults to `URLSession.shared`. |

### lookup(ip:lang:)

```swift
func lookup(ip: String? = nil, lang: IP2Language? = nil) async throws -> IP2LocationResult
```

Retrieves the geolocation information for an IP address.

| Parameter | Description |
| --- | --- |
| `ip` | (Optional) The IPv4 or IPv6 address. When `nil`, the API resolves the requester's own IP address. |
| `lang` | (Optional) Translation language. Overrides the client default. |

**Return:** An `IP2LocationResult` holding the geolocation information. Refer to the field table below.

**Throws:** `IP2LocationError`.

### lookup(ip:lang:completion:)

```swift
func lookup(ip: String? = nil,
            lang: IP2Language? = nil,
            completion: @escaping (Result<IP2LocationResult, IP2LocationError>) -> Void)
```

The completion-handler form of `lookup(ip:lang:)`. The completion handler receives either the result or an `IP2LocationError`.

## IP2LocationBulk Class

```swift
IP2LocationBulk(apiKey: String? = nil,
                authStyle: IP2Location.AuthStyle = .queryParameter,
                baseURL: URL = URL(string: "https://bulk.ip2location.io/")!,
                session: any IP2LocationNetworking = URLSession.shared)
```

Creates a client for the IP2Location.io bulk lookup endpoint. The bulk endpoint accepts up to 1,000 IP addresses per request and requires a paid plan.

| Parameter | Description |
| --- | --- |
| `apiKey` | (Required) Your API key. |
| `authStyle` | (Optional) How the API key is transmitted. Defaults to `.queryParameter`. |
| `baseURL` | (Optional) API endpoint. Defaults to `https://bulk.ip2location.io/`. |
| `session` | (Optional) Transport used for requests. Defaults to `URLSession.shared`. |

### lookup(ips:fields:)

```swift
func lookup(ips: [String], fields: [String]? = nil) async throws -> IP2LocationBulkResult
```

Retrieves the geolocation information for one or more IP addresses in a single POST request.

| Parameter | Description |
| --- | --- |
| `ips` | (Required) The IPv4 and IPv6 addresses to look up, up to 1,000. |
| `fields` | (Optional) Subset of response fields to return, for example `["country_code", "isp"]`. When `nil`, every field is returned. |

**Return:** An `IP2LocationBulkResult`. Refer to the field table below.

**Throws:** `IP2LocationError`.

### lookup(ips:fields:completion:)

```swift
func lookup(ips: [String],
            fields: [String]? = nil,
            completion: @escaping (Result<IP2LocationBulkResult, IP2LocationError>) -> Void)
```

The completion-handler form of `lookup(ips:fields:)`.

## IP2LocationResult

Holds the geolocation information returned for a single IP address. Every property is optional, because the fields returned depend on your plan.

### Basic geolocation (Free plan)

| Property | JSON field | Description |
| --- | --- | --- |
| `ip` | `ip` | IP address. |
| `countryCode` | `country_code` | Two-character country code based on ISO 3166. |
| `countryName` | `country_name` | Country name based on ISO 3166. |
| `regionName` | `region_name` | Region or state name. |
| `cityName` | `city_name` | City name. |
| `latitude` | `latitude` | City latitude. Defaults to the capital city latitude if the city is unknown. |
| `longitude` | `longitude` | City longitude. Defaults to the capital city longitude if the city is unknown. |
| `zipCode` | `zip_code` | ZIP or postal code. |
| `timeZone` | `time_zone` | UTC time zone, with DST supported. |
| `asn` | `asn` | Autonomous system number (ASN). |
| `asName` | `as` | Autonomous system (AS) name. |
| `isProxy` | `is_proxy` | Whether the IP address belongs to a known proxy, VPN, Tor exit node or another masking service. |

:::{note}
The JSON field `as` is a reserved keyword in Swift, so it is exposed as `asName`.
:::

### Advanced geolocation (Starter plan)

| Property | JSON field | Description |
| --- | --- | --- |
| `isp` | `isp` | Internet Service Provider or company name. |
| `domain` | `domain` | Internet domain name associated with the IP address range. |
| `netSpeed` | `net_speed` | Internet connection type: DIAL, DSL, COMP, T1 or SAT. |
| `iddCode` | `idd_code` | IDD prefix used to call the city from another country. |
| `areaCode` | `area_code` | Number assigned to geographic areas for calls between cities. |
| `weatherStationCode` | `weather_station_code` | Code identifying the nearest weather observation station. |
| `weatherStationName` | `weather_station_name` | Name of the nearest weather observation station. |
| `elevation` | `elevation` | Average height of the city above sea level, in meters. |
| `usageType` | `usage_type` | Usage type of the ISP or company. |

### Mobile and address type (Plus plan)

| Property | JSON field | Description |
| --- | --- | --- |
| `mcc` | `mcc` | Mobile Country Code (MCC) as defined in ITU E.212. |
| `mnc` | `mnc` | Mobile Network Code (MNC). |
| `mobileBrand` | `mobile_brand` | Commercial brand associated with the mobile carrier. |
| `addressType` | `address_type` | IP address type: Anycast, Unicast, Multicast or Broadcast. |

### Objects (Plus plan)

| Property | JSON field | Description |
| --- | --- | --- |
| `continent` | `continent` | Continent object. |
| `country` | `country` | Country object. |
| `region` | `region` | Region object. |
| `city` | `city` | City object. |
| `timeZoneInfo` | `time_zone_info` | Time zone info object. |
| `geotargeting` | `geotargeting` | Geotargeting object. |

### Security data (Security plan)

| Property | JSON field | Description |
| --- | --- | --- |
| `district` | `district` | District or county name. |
| `asInfo` | `as_info` | Autonomous system info object. |
| `adsCategory` | `ads_category` | Domain category code based on the IAB Tech Lab Content Taxonomy. |
| `adsCategoryName` | `ads_category_name` | Domain category name based on the IAB Tech Lab Content Taxonomy. |
| `fraudScore` | `fraud_score` | Potential risk score from 0 to 99. A higher score indicates a greater likelihood of fraudulent activity. |
| `proxy` | `proxy` | Proxy object. |

### Nested objects

**`continent`**

| Property | Description |
| --- | --- |
| `name` | Continent name. |
| `code` | Two-character continent code. |
| `hemisphere` | Array of two strings: the north/south hemisphere, then the east/west hemisphere. |
| `translation` | Translation object for the requested language. |

**`country`**

| Property | Description |
| --- | --- |
| `name` | Country name based on ISO 3166. |
| `alpha3Code` | Three-character country code based on ISO 3166. |
| `numericCode` | Three-character country numeric code based on ISO 3166. |
| `demonym` | Name for a native of the country. |
| `flag` | URL of the country flag image. |
| `capital` | Capital of the country. |
| `totalArea` | Total area in square kilometres. |
| `population` | Population of the country. |
| `currency` | Currency object with `code`, `name` and `symbol`. |
| `language` | Language object with `code` and `name`. |
| `tld` | Country-code top-level domain. |
| `translation` | Translation object for the requested language. |

**`region`**

| Property | Description |
| --- | --- |
| `name` | Region or state name. |
| `code` | ISO 3166-2 code. |
| `translation` | Translation object for the requested language. |

**`city`**

| Property | Description |
| --- | --- |
| `name` | City name. |
| `translation` | Translation object for the requested language. |

**`translation`**

| Property | Description |
| --- | --- |
| `lang` | Language code of the translation. |
| `value` | Translated text. |

**`timeZoneInfo`**

| Property | Description |
| --- | --- |
| `olson` | Time zone in Olson format. |
| `currentTime` | Current time in ISO 8601 format. |
| `gmtOffset` | GMT offset value in seconds. |
| `isDst` | Whether the time zone value is in DST. |
| `abbreviation` | Time zone abbreviation, for example EST or EEST. |
| `dstStartDate` | Date, in UTC, on which DST begins. |
| `dstEndDate` | Date, in UTC, on which DST ends. |
| `sunrise` | Time of sunrise in `hh:mm` local time. |
| `sunset` | Time of sunset in `hh:mm` local time. |

**`geotargeting`**

| Property | Description |
| --- | --- |
| `metro` | Metro code based on the ZIP or postal code. |

**`asInfo`**

| Property | Description |
| --- | --- |
| `asNumber` | Autonomous system number (ASN). |
| `asName` | Autonomous system (AS) name. |
| `asDomain` | Domain name of the AS registrant. |
| `asUsageType` | Usage type of the AS registrant. |
| `asCidr` | CIDR range for the whole AS. |

**`proxy`**

| Property | Description |
| --- | --- |
| `lastSeen` | Number of days since the proxy was last seen. |
| `proxyType` | Type of proxy: VPN, TOR, DCH, PUB, WEB, SES, AIC, RES, CPN or EPN. |
| `threat` | Security threat reported: SPAM, SCANNER, BOTNET or BOGON. |
| `provider` | Name of the VPN provider, when available. |
| `isVPN` | Anonymizing VPN services. |
| `isTor` | Tor exit nodes. |
| `isDataCenter` | Hosting provider, data center or content delivery network. |
| `isPublicProxy` | Public proxies. |
| `isWebProxy` | Web proxies. |
| `isWebCrawler` | Search engine robots. |
| `isAICrawler` | AI crawlers, used for LLM training data or real-time retrieval. |
| `isResidentialProxy` | Residential proxies. |
| `isConsumerPrivacyNetwork` | Consumer privacy networks. |
| `isEnterprisePrivateNetwork` | Enterprise private networks. |
| `isSpammer` | Email and forum spammers. |
| `isScanner` | Network security scanners. |
| `isBotnet` | Malware infected devices. |
| `isBogon` | Unassigned or illegitimate IP addresses announced via BGP. |

## IP2LocationBulkResult

Holds the outcome of a bulk lookup.

| Property | Description |
| --- | --- |
| `results` | Dictionary of `IP2LocationResult` values keyed by IP address. Populated on success. |
| `error` | `IP2LocationAPIError` value. Populated when the API returns an error object. |

## IP2Language

Languages accepted by the `lang` parameter. Translations apply to the continent, country, region and city names, and are only available on the Plus and Security plans.

| Case | Value |
| --- | --- |
| `arabic` | `ar` |
| `czech` | `cs` |
| `danish` | `da` |
| `german` | `de` |
| `english` | `en` |
| `spanish` | `es` |
| `estonian` | `et` |
| `finnish` | `fi` |
| `french` | `fr` |
| `irish` | `ga` |
| `italian` | `it` |
| `japanese` | `ja` |
| `korean` | `ko` |
| `malay` | `ms` |
| `dutch` | `nl` |
| `portuguese` | `pt` |
| `russian` | `ru` |
| `swedish` | `sv` |
| `turkish` | `tr` |
| `vietnamese` | `vi` |
| `chineseSimplified` | `zh-cn` |
| `chineseTraditional` | `zh-tw` |

## IP2LocationError

Reported for network and API failures.

| Case | Description |
| --- | --- |
| `invalidURL` | The request URL could not be built. |
| `invalidResponse` | The response was not a valid HTTP response. |
| `decodingFailed` | The response body could not be decoded. |
| `httpStatus(Int)` | The server returned a non-2xx status code with no decodable error payload. |
| `apiError(code: Int, message: String)` | The API returned an error object. |
| `transport(Error)` | A networking error occurred while performing the request. |

## IP2LocationAPIError

The error object returned by the API, together with the documented error codes.

| Constant | Code | Meaning |
| --- | --- | --- |
| `invalidAPIKey` | 10000 | Invalid API key or insufficient query. |
| `invalidIPAddress` | 10001 | Invalid IP address. |
| `internalServerError` | 10002 | Internal server error. |
| `invalidLanguageCode` | 10003 | Invalid language code. |
| `translationNotAvailable` | 10004 | Translation is not available with your plan. |
| `bulkInvalidAPIKey` | 401 | Invalid API key or insufficient query (bulk endpoint). |
| `bulkInternalServerError` | 500 | Internal server error (bulk endpoint). |

| Property | Description |
| --- | --- |
| `errorCode` | Numeric error code. |
| `errorMessage` | Human-readable description of the error. |

## IP2LocationNetworking

Protocol abstracting the HTTP transport, so the client can be used with a mock in tests instead of `URLSession`.

| Method | Description |
| --- | --- |
| `perform(_:completion:)` | Performs a request and delivers the raw data, response and error to the completion handler. `URLSession` conforms to this protocol out of the box. |
