import Foundation

/// A geolocation result returned by the IP2Location.io Lookup API.
///
/// Every property is optional because the fields returned by the API depend on
/// the plan the API key is subscribed to (Free / Starter / Plus / Security).
/// Properties that are not part of the active plan simply decode to `nil`.
///
/// JSON key names use snake_case (e.g. `country_code`); they are mapped to
/// camelCase Swift properties. The one exception is the top-level `as` field,
/// which is a reserved keyword in Swift and is therefore exposed as `asName`.
public struct IP2LocationResult: Codable, Sendable, Equatable {

    // MARK: - Basic geolocation (Free plan)

    /// IP address that was looked up.
    public var ip: String?
    /// Two-character country code based on ISO 3166.
    public var countryCode: String?
    /// Country name based on ISO 3166.
    public var countryName: String?
    /// Region or state name.
    public var regionName: String?
    /// City name.
    public var cityName: String?
    /// City latitude (defaults to the capital city latitude if unknown).
    public var latitude: Double?
    /// City longitude (defaults to the capital city longitude if unknown).
    public var longitude: Double?
    /// ZIP/Postal code.
    public var zipCode: String?
    /// UTC time zone (with DST supported).
    public var timeZone: String?

    // MARK: - Basic AS & proxy (Free plan)

    /// Autonomous system number (ASN).
    public var asn: String?
    /// Autonomous system (AS) name. Maps to the JSON key `as`.
    public var asName: String?
    /// Whether the IP address belongs to a known proxy, VPN, Tor exit node,
    /// or another type of masking service.
    public var isProxy: Bool?

    // MARK: - Advanced geolocation (Starter plan)

    /// Internet Service Provider or company name.
    public var isp: String?
    /// Internet domain name associated with the IP address range.
    public var domain: String?
    /// Internet connection type (DIAL, DSL, COMP, T1, SAT).
    public var netSpeed: String?
    /// IDD prefix to call the city from another country.
    public var iddCode: String?
    /// Varying length number assigned to geographic areas for calls between cities.
    public var areaCode: String?
    /// Special code identifying the nearest weather observation station.
    public var weatherStationCode: String?
    /// Name of the nearest weather observation station.
    public var weatherStationName: String?
    /// Average height of the city above sea level in meters.
    public var elevation: Int?
    /// Usage type classification of the ISP or company.
    public var usageType: String?

    // MARK: - Mobile & address type (Plus plan)

    /// Mobile Country Code (MCC) as defined in ITU E.212.
    public var mcc: String?
    /// Mobile Network Code (MNC).
    public var mnc: String?
    /// Commercial brand associated with the mobile carrier.
    public var mobileBrand: String?
    /// IP address type (Anycast, Unicast, Multicast, Broadcast).
    public var addressType: String?

    // MARK: - Comprehensive objects (Plus plan)

    public var continent: Continent?
    public var country: Country?
    public var region: Region?
    public var city: City?
    public var timeZoneInfo: TimeZoneInfo?
    public var geotargeting: GeoTargeting?

    // MARK: - Security plan

    /// District or county name.
    public var district: String?
    public var asInfo: ASInfo?
    /// Domain category code based on the IAB Tech Lab Content Taxonomy.
    public var adsCategory: String?
    /// Domain category based on the IAB Tech Lab Content Taxonomy.
    public var adsCategoryName: String?
    /// Potential risk score (0 - 99) associated with the IP address.
    public var fraudScore: Int?
    public var proxy: ProxyInfo?

    // MARK: - API error envelope

    /// Populated when the API responds with an error object, e.g.
    /// `{ "error": { "error_code": 10001, "error_message": "Invalid IP address." } }`.
    public var error: IP2LocationAPIError?

    public init() {}

    enum CodingKeys: String, CodingKey {
        case ip, asn, isp, domain, district
        case countryCode = "country_code"
        case countryName = "country_name"
        case regionName = "region_name"
        case cityName = "city_name"
        case latitude, longitude
        case zipCode = "zip_code"
        case timeZone = "time_zone"
        case asName = "as"
        case isProxy = "is_proxy"
        case netSpeed = "net_speed"
        case iddCode = "idd_code"
        case areaCode = "area_code"
        case weatherStationCode = "weather_station_code"
        case weatherStationName = "weather_station_name"
        case elevation
        case usageType = "usage_type"
        case mcc, mnc
        case mobileBrand = "mobile_brand"
        case addressType = "address_type"
        case continent, country, region, city
        case timeZoneInfo = "time_zone_info"
        case geotargeting
        case asInfo = "as_info"
        case adsCategory = "ads_category"
        case adsCategoryName = "ads_category_name"
        case fraudScore = "fraud_score"
        case proxy, error
    }

    // MARK: - Nested types

    /// Continent object.
    public struct Continent: Codable, Sendable, Equatable {
        public var name: String?
        public var code: String?
        /// First item indicates the north/south hemisphere, second item the
        /// east/west hemisphere.
        public var hemisphere: [String]?
        public var translation: Translation?
        public init() {}
    }

    /// Translation data based on the requested `lang` code.
    public struct Translation: Codable, Sendable, Equatable {
        public var lang: String?
        public var value: String?
        public init() {}
    }

    /// Country object.
    public struct Country: Codable, Sendable, Equatable {
        public var name: String?
        /// Three-character country code based on ISO 3166.
        public var alpha3Code: String?
        /// Three-character country numeric code based on ISO 3166.
        public var numericCode: Int?
        /// Native of the country.
        public var demonym: String?
        /// URL of the country flag image.
        public var flag: String?
        /// Capital of the country.
        public var capital: String?
        /// Total area in km².
        public var totalArea: Int?
        /// Population of the country.
        public var population: Int?
        public var currency: Currency?
        public var language: Language?
        /// Country-Code Top-Level Domain.
        public var tld: String?
        public var translation: Translation?
        public init() {}

        public struct Currency: Codable, Sendable, Equatable {
            public var code: String?
            public var name: String?
            public var symbol: String?
            public init() {}
        }

        public struct Language: Codable, Sendable, Equatable {
            public var code: String?
            public var name: String?
            public init() {}
        }

        enum CodingKeys: String, CodingKey {
            case name, demonym, flag, capital, population, currency, language, tld, translation
            case alpha3Code = "alpha3_code"
            case numericCode = "numeric_code"
            case totalArea = "total_area"
        }
    }

    /// Region or state object.
    public struct Region: Codable, Sendable, Equatable {
        public var name: String?
        /// ISO 3166-2 code.
        public var code: String?
        public var translation: Translation?
        public init() {}
    }

    /// City object.
    public struct City: Codable, Sendable, Equatable {
        public var name: String?
        public var translation: Translation?
        public init() {}
    }

    /// Time zone info object.
    public struct TimeZoneInfo: Codable, Sendable, Equatable {
        /// Time zone in Olson format.
        public var olson: String?
        /// Current time in ISO 8601 format.
        public var currentTime: String?
        /// GMT offset value in seconds.
        public var gmtOffset: Int?
        /// Whether the time zone value is in DST.
        public var isDst: Bool?
        /// Time zone abbreviation, e.g. EST, EEST.
        public var abbreviation: String?
        /// Date (UTC) DST begins.
        public var dstStartDate: String?
        /// Date (UTC) DST ends.
        public var dstEndDate: String?
        /// Time of sunrise (hh:mm in local time).
        public var sunrise: String?
        /// Time of sunset (hh:mm in local time).
        public var sunset: String?
        public init() {}

        enum CodingKeys: String, CodingKey {
            case olson, abbreviation, sunrise, sunset
            case currentTime = "current_time"
            case gmtOffset = "gmt_offset"
            case isDst = "is_dst"
            case dstStartDate = "dst_start_date"
            case dstEndDate = "dst_end_date"
        }
    }

    /// Geotargeting object.
    public struct GeoTargeting: Codable, Sendable, Equatable {
        /// Metro code based on the ZIP/postal code.
        public var metro: String?
        public init() {}
    }

    /// Autonomous system (AS) info object.
    public struct ASInfo: Codable, Sendable, Equatable {
        /// Autonomous system number (ASN).
        public var asNumber: String?
        /// Autonomous system (AS) name.
        public var asName: String?
        /// Domain name of the AS registrant.
        public var asDomain: String?
        /// Usage type of the AS registrant.
        public var asUsageType: String?
        /// CIDR range for the whole AS.
        public var asCidr: String?
        public init() {}

        enum CodingKeys: String, CodingKey {
            case asNumber = "as_number"
            case asName = "as_name"
            case asDomain = "as_domain"
            case asUsageType = "as_usage_type"
            case asCidr = "as_cidr"
        }
    }

    /// Proxy / VPN detection object.
    public struct ProxyInfo: Codable, Sendable, Equatable {
        /// Proxy last seen, in days.
        public var lastSeen: Int?
        /// Type of proxy (VPN, TOR, DCH, PUB, WEB, SES, AIC, RES, CPN, EPN).
        public var proxyType: String?
        /// Security threat reported (SPAM, SCANNER, BOTNET, BOGON).
        public var threat: String?
        /// Name of the VPN provider, if available.
        public var provider: String?
        /// Anonymizing VPN services.
        public var isVPN: Bool?
        /// Tor exit nodes.
        public var isTor: Bool?
        /// Hosting provider, data center or CDN.
        public var isDataCenter: Bool?
        /// Public proxies.
        public var isPublicProxy: Bool?
        /// Web proxies.
        public var isWebProxy: Bool?
        /// Search engine robots.
        public var isWebCrawler: Bool?
        /// AI crawlers (LLM training / RAG retrieval).
        public var isAICrawler: Bool?
        /// Residential proxies.
        public var isResidentialProxy: Bool?
        /// Consumer privacy networks.
        public var isConsumerPrivacyNetwork: Bool?
        /// Enterprise private networks.
        public var isEnterprisePrivateNetwork: Bool?
        /// Email and forum spammers.
        public var isSpammer: Bool?
        /// Network security scanners.
        public var isScanner: Bool?
        /// Malware infected devices.
        public var isBotnet: Bool?
        /// Unassigned or illegitimate IP addresses announced via BGP.
        public var isBogon: Bool?
        public init() {}

        enum CodingKeys: String, CodingKey {
            case provider, threat
            case lastSeen = "last_seen"
            case proxyType = "proxy_type"
            case isVPN = "is_vpn"
            case isTor = "is_tor"
            case isDataCenter = "is_data_center"
            case isPublicProxy = "is_public_proxy"
            case isWebProxy = "is_web_proxy"
            case isWebCrawler = "is_web_crawler"
            case isAICrawler = "is_ai_crawler"
            case isResidentialProxy = "is_residential_proxy"
            case isConsumerPrivacyNetwork = "is_consumer_privacy_network"
            case isEnterprisePrivateNetwork = "is_enterprise_private_network"
            case isSpammer = "is_spammer"
            case isScanner = "is_scanner"
            case isBotnet = "is_botnet"
            case isBogon = "is_bogon"
        }
    }
}
