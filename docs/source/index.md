IP2Location (Swift SDK)
=======================

*This is the official release maintained by IP2Location.com*

This Swift SDK provides fast lookup of country, region, district, city, latitude, longitude, ZIP code, time zone, ISP, domain name, connection speed, IDD code, area code, weather station code, MNC, MCC, mobile brand, elevation, usage type, address type, IAB category and ASN for an IP address by using the [IP2Location.io](https://www.ip2location.io) geolocation API. Both the single lookup and the bulk lookup endpoints are supported, for IPv4 and IPv6.

The SDK has no third-party dependencies and works on iOS, macOS, tvOS and watchOS through Swift Package Manager.

Where the module can be used:

1. Select the geographically closest mirror
2. Analyze your web server logs to determine the countries of your visitors
3. Credit card fraud detection
4. Software export controls
5. Display native language and currency
6. Prevent password sharing and abuse of service
7. Geotargeting in advertisement

The IP2Location.io API does not require an API key for up to 1,000 queries per day. A free API key raises the limit to 50,000 queries per month, and paid plans unlock the additional fields and the bulk endpoint.

## KEY FEATURES

1. **Support both IPv4 and IPv6 with ease.** Pass either address family to the same `lookup()` call, with no code change.
2. **No dependencies.** Foundation only, so nothing else is added to your app.
3. **Modern and legacy APIs.** Every call is available as both `async throws` and a completion handler.
4. **Complete result model.** All fields from the Free, Starter, Plus and Security plans are decoded into typed properties, including the nested `country`, `region`, `city`, `time_zone_info`, `as_info` and `proxy` objects.
5. **Bulk lookup.** Up to 1,000 addresses per request on the bulk endpoint.
6. **Testable by design.** Networking goes through the `IP2LocationNetworking` protocol, so tests need no network access.

## Table of contents

```{eval-rst}
.. toctree::

   self
   quickstart
   code
```
