import Foundation
import IP2LocationSwift

/// Full-featured example for the IP2LocationSwift SDK.
///
/// Demonstrates the entire public API surface:
///   - keyless and API-key clients
///   - async/await and completion-handler lookup
///   - self, IPv4 and IPv6 lookups
///   - localized names (`lang`) and Bearer-token auth
///   - reading every group of response fields, including nested objects
///   - API error handling
///
/// Usage:
///   export IP2LOCATION_API_KEY="YOUR_API_KEY"   # optional — keyless if unset
///   swift run IP2LocationExample                 # looks up this machine's IP
///   swift run IP2LocationExample 8.8.8.8
///   swift run IP2LocationExample 2001:4860:4860::8888
///
/// Note: this example performs real network calls to api.ip2location.io.
@main
struct IP2LocationExample {

    static func main() async {
        let apiKey = ProcessInfo.processInfo.environment["IP2LOCATION_API_KEY"]
        let args = Array(CommandLine.arguments.dropFirst())

        print("┌──────────────────────────────────────────────")
        print("│ IP2LocationSwift — full example")
        print("│ auth: \(apiKey == nil ? "keyless (1,000 queries/day)" : "API key from IP2LOCATION_API_KEY")")
        print("└──────────────────────────────────────────────")
        print()

        // 1) Keyless self lookup — no apiKey, no ip => resolves the requester.
        print("▶ 1. Keyless self lookup")
        let keyless = IP2Location() // no API key
        await runAndPrint(nil, client: keyless)

        // 2) Explicit IPv4 lookup with the API key (query-parameter auth).
        let client = IP2Location(apiKey: apiKey, lang: .english)
        let target = args.first ?? "8.8.8.8"
        print("▶ 2. Explicit lookup: \(target) (query-parameter auth)")
        await runAndPrint(target, client: client)

        // 3) IPv6 lookup.
        print("▶ 3. IPv6 lookup: 2001:4860:4860::8888")
        await runAndPrint("2001:4860:4860::8888", client: client)

        // 4) Localized names (Plus / Security plans only).
        print("▶ 4. Localized lookup (lang: Korean)")
        let koClient = IP2Location(apiKey: apiKey, lang: .korean)
        await runAndPrint("8.8.8.8", client: koClient)

        // 5) Completion-handler API (awaited here so the example stays linear).
        print("▶ 5. Completion-handler lookup")
        await runWithCompletion(target, client: client)

        // 6) Bearer-token auth.
        print("▶ 6. Bearer-token auth lookup")
        let bearerClient = IP2Location(apiKey: apiKey, authStyle: .bearerToken)
        await runAndPrint("8.8.8.8", client: bearerClient)

        // 7) Error handling — an invalid IP produces the documented API error.
        print("▶ 7. Error handling (invalid IP: 999.999.999.999)")
        do {
            _ = try await client.lookup(ip: "999.999.999.999")
            print("   ⚠ expected an error but the lookup succeeded")
        } catch {
            printError(error)
        }

        // 8) Bulk lookup — requires a paid plan.
        if apiKey != nil {
            print("▶ 8. Bulk lookup: 8.8.8.8, 1.1.1.1")
            let bulk = IP2LocationBulk(apiKey: apiKey, authStyle: .queryParameter)
            do {
                let bulkResult = try await bulk.lookup(ips: ["8.8.8.8", "1.1.1.1"])
                for (ip, info) in bulkResult.results?.sorted(by: { $0.key < $1.key }) ?? [] {
                    print("   \(ip) → \(info.countryName ?? "?"), \(info.cityName ?? "?") (\(info.isp ?? "?"))")
                }
            } catch {
                printError(error)
            }
        } else {
            print("▶ 8. Bulk lookup (skipped — requires an API key)")
        }

        print()
        print("Done.")
    }

    // MARK: - Helpers

    private static func runAndPrint(_ ip: String?, client: IP2Location) async {
        do {
            let result = try await client.lookup(ip: ip)
            printResult(result, label: ip ?? "self")
        } catch {
            printError(error)
        }
        print()
    }

    private static func runWithCompletion(_ ip: String, client: IP2Location) async {
        do {
            let result: IP2LocationResult = try await withCheckedThrowingContinuation { continuation in
                client.lookup(ip: ip) { outcome in
                    switch outcome {
                    case .success(let info):
                        continuation.resume(returning: info)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
            print("   OK country=\(result.countryCode ?? "?")  city=\(result.cityName ?? "?")  isp=\(result.isp ?? "?")")
        } catch {
            printError(error)
        }
        print()
    }

    private static func printResult(_ r: IP2LocationResult, label: String) {
        print("   ── \(label) ────────────────────────────────")
        print("   IP           \(r.ip ?? "-")")
        print("   Country      \(r.countryName ?? "-") (\(r.countryCode ?? "-"))")
        print("   Region       \(r.regionName ?? "-")")
        if let district = r.district { print("   District     \(district)") }
        print("   City         \(r.cityName ?? "-")")
        print("   Coordinates  \(r.latitude.map { String($0) } ?? "-"), \(r.longitude.map { String($0) } ?? "-")")
        print("   ZIP / TZ     \(r.zipCode ?? "-") / \(r.timeZone ?? "-")")
        print("   ASN / AS     \(r.asn ?? "-") / \(r.asName ?? "-")")
        print("   ISP / Domain \(r.isp ?? "-") / \(r.domain ?? "-")")
        print("   Net speed    \(r.netSpeed ?? "-")   usage=\(r.usageType ?? "-")")
        if r.mcc != nil || r.mnc != nil {
            print("   Mobile       MCC=\(r.mcc ?? "-")  MNC=\(r.mnc ?? "-")  brand=\(r.mobileBrand ?? "-")")
        }
        print("   Address type \(r.addressType ?? "-")   ads=\(r.adsCategoryName ?? "-")")
        print("   Proxy        \(r.isProxy.map { String($0) } ?? "-")   fraudScore=\(r.fraudScore.map { String($0) } ?? "-")")

        if let country = r.country {
            print("   ── country object ─────────────────────────")
            print("   Name         \(country.name ?? "-")")
            print("   Alpha3/num   \(country.alpha3Code ?? "-") / \(country.numericCode.map { String($0) } ?? "-")")
            print("   Capital      \(country.capital ?? "-")   area=\(country.totalArea.map { String($0) } ?? "-") km²  pop=\(country.population.map { String($0) } ?? "-")")
            print("   Currency     \(country.currency?.code ?? "-") \(country.currency?.name ?? "-") \(country.currency?.symbol ?? "-")")
            print("   Language     \(country.language?.name ?? "-") (\(country.language?.code ?? "-"))")
            print("   TLD / Flag   \(country.tld ?? "-") / \(country.flag ?? "-")")
            if let value = country.translation?.value { print("   Translation  \(value)") }
        }

        if let tz = r.timeZoneInfo {
            print("   ── time zone info ────────────────────────")
            print("   Olson        \(tz.olson ?? "-")")
            print("   Local time   \(tz.currentTime ?? "-")")
            print("   GMT offset   \(tz.gmtOffset.map { String($0) } ?? "-") s   DST=\(tz.isDst.map { String($0) } ?? "-")")
            print("   Sunrise/set  \(tz.sunrise ?? "-") / \(tz.sunset ?? "-")")
        }

        if let proxy = r.proxy {
            print("   ── proxy object ──────────────────────────")
            print("   Type         \(proxy.proxyType ?? "-")   lastSeen=\(proxy.lastSeen.map { String($0) } ?? "-")d")
            print("   VPN/TOR/DC   \(proxy.isVPN.map { String($0) } ?? "-") / \(proxy.isTor.map { String($0) } ?? "-") / \(proxy.isDataCenter.map { String($0) } ?? "-")")
        }
    }

    private static func printError(_ error: Error) {
        if let ip2error = error as? IP2LocationError {
            switch ip2error {
            case .apiError(let code, let message):
                print("   ✗ API error \(code): \(message)")
            case .httpStatus(let code):
                print("   ✗ HTTP status \(code)")
            case .transport(let underlying):
                print("   ✗ Network error: \(underlying.localizedDescription)")
            default:
                print("   ✗ \(ip2error.localizedDescription)")
            }
        } else {
            print("   ✗ \(error)")
        }
    }
}
