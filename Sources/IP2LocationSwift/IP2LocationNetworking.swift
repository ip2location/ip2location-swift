import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Abstraction over `URLSession` so the client can be tested with a mock
/// transport that does not hit the network.
public protocol IP2LocationNetworking: Sendable {
    /// Performs an HTTP request and delivers the raw response to `completion`.
    /// The implementation owns scheduling — `URLSession` starts its task and
    /// calls `.resume()` automatically.
    func perform(_ request: URLRequest,
                 completion: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void)
}

extension URLSession: IP2LocationNetworking {
    public func perform(_ request: URLRequest,
                        completion: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) {
        dataTask(with: request, completionHandler: completion).resume()
    }
}
