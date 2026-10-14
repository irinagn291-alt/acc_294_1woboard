import Foundation

/// One client for the optional bracket title search.
/// User-Agent is Callboard/1.0. Timeout is 15 seconds. One retry on a transient
/// transport failure. A 404 is not retried. Decode uses default keys, then maps to ShelfTitle.
actor TitleShelfClient {
    static let userAgent = "Callboard/1.0 (iOS; +https://callboard-floor.pro)"
    static let pageSize = 20

    private let transport: any HouseTransport
    private let cacheDirectory: URL
    private let debounceNanoseconds: UInt64
    private let endpoint: URL
    private var generation: UInt64 = 0
    private var networkTask: Task<Data, Error>?

    init(
        transport: any HouseTransport,
        cacheDirectory: URL,
        endpoint: URL? = nil,
        debounceNanoseconds: UInt64 = 300_000_000
    ) {
        self.transport = transport
        self.cacheDirectory = cacheDirectory
        if let endpoint {
            self.endpoint = endpoint
        } else if let built = URL(string: "https://openlibrary.org/cgi/search.pl") {
            self.endpoint = built
        } else {
            self.endpoint = URL(fileURLWithPath: "/cgi/search.pl")
        }
        self.debounceNanoseconds = debounceNanoseconds
    }

    /// Cancels the previous query. A stale response cannot overwrite a newer one.
    func lookup(_ query: String) async -> LookupResult {
        generation &+= 1
        let token = generation
        networkTask?.cancel()
        do {
            try await Task.sleep(nanoseconds: debounceNanoseconds)
        } catch {
            return .cancelled
        }
        guard token == generation else { return .cancelled }
        do {
            let remote = try await search(query, token: token)
            guard token == generation else { return .cancelled }
            if remote.isEmpty {
                return .titles(LocalShelf.match(query))
            }
            storeCache(query, remote)
            return .titles(remote)
        } catch is CancellationError {
            return .cancelled
        } catch {
            guard token == generation else { return .cancelled }
            if let cached = loadCache(query), !cached.isEmpty {
                return .titles(cached)
            }
            return .titles(LocalShelf.match(query))
        }
    }

    func search(_ query: String, token: UInt64) async throws -> [ShelfTitle] {
        var parts = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        parts?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page_size", value: String(Self.pageSize)),
            URLQueryItem(name: "format", value: "json")
        ]
        guard let url = parts?.url else {
            throw ShelfFailure.malformed
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        let task = Task { try await self.fetch(request) }
        networkTask = task
        let data: Data
        do {
            data = try await task.value
        } catch {
            throw error
        }
        guard token == generation else { throw CancellationError() }
        return try Self.mapTitles(data)
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        do {
            return try await once(request)
        } catch ShelfFailure.notFound {
            throw ShelfFailure.notFound
        } catch {
            guard Self.isRetryable(error) else { throw error }
            return try await once(request)
        }
    }

    private func once(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await transport.send(request)
        switch response.statusCode {
        case 200:
            return data
        case 404:
            throw ShelfFailure.notFound
        case 408, 429, 500, 502, 503, 504:
            throw ShelfFailure.transient(response.statusCode)
        default:
            throw ShelfFailure.status(response.statusCode)
        }
    }

    static func mapTitles(_ data: Data) throws -> [ShelfTitle] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let page: SearchPageDTO
        do {
            page = try decoder.decode(SearchPageDTO.self, from: data)
        } catch {
            throw ShelfFailure.malformed
        }
        return (page.docs ?? []).compactMap { doc in
            guard let title = doc.title, !title.isEmpty else { return nil }
            let id = doc.key ?? title
            return ShelfTitle(id: id, title: title)
        }
    }

    private static func isRetryable(_ error: Error) -> Bool {
        if let failure = error as? ShelfFailure, case .transient = failure {
            return true
        }
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed, .notConnectedToInternet:
            return true
        default:
            return false
        }
    }

    private func storeCache(_ query: String, _ titles: [ShelfTitle]) {
        let folder = cacheDirectory
        let manager = FileManager.default
        do {
            try manager.createDirectory(at: folder, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var mutable = folder
            try mutable.setResourceValues(values)
            let payload = try JSONEncoder().encode(titles.map { CachedTitle(id: $0.id, title: $0.title) })
            try payload.write(to: folder.appendingPathComponent(Self.cacheName(query)), options: .atomic)
        } catch {
            // The in-memory titles for this lookup stay valid when the cache file cannot be written.
            _ = error.localizedDescription
        }
    }

    private func loadCache(_ query: String) -> [ShelfTitle]? {
        let url = cacheDirectory.appendingPathComponent(Self.cacheName(query))
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        guard let rows = try? decoder.decode([CachedTitle].self, from: data) else { return nil }
        return rows.map { ShelfTitle(id: $0.id, title: $0.title) }
    }

    private static func cacheName(_ query: String) -> String {
        let cleaned = query.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }
        let stem = String(String.UnicodeScalarView(cleaned))
        if stem.isEmpty { return "blank.json" }
        return String(stem.prefix(80)) + ".json"
    }
}

enum LookupResult: Equatable, Sendable {
    case titles([ShelfTitle])
    case cancelled
}

enum ShelfFailure: Error, Equatable, Sendable {
    case notFound
    case transient(Int)
    case status(Int)
    case malformed
}

protocol HouseTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

struct URLSessionTransport: HouseTransport {
    let session: URLSession

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 15
            configuration.timeoutIntervalForResource = 15
            self.session = URLSession(configuration: configuration)
        }
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ShelfFailure.status(-1)
        }
        return (data, http)
    }
}

struct SearchPageDTO: Decodable, Sendable {
    var docs: [SearchDocDTO]?
}

struct SearchDocDTO: Decodable, Sendable {
    var title: String?
    var key: String?
}

private struct CachedTitle: Codable {
    var id: String
    var title: String
}
