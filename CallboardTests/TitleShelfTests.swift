import XCTest
@testable import Callboard

final class TitleShelfTests: XCTestCase {
    func test_userAgentPageSizeAndDecode() async throws {
        let transport = ScriptedTransport()
        let body = Data(#"{"docs":[{"key":"/works/OL1W","title":"North Window Set"}]}"#.utf8)
        await transport.enqueue(data: body, status: 200)
        let client = client(transport, debounce: 0)
        let result = await client.lookup("north")
        guard case .titles(let titles) = result else {
            XCTFail("Expected titles")
            return
        }
        XCTAssertEqual(titles.first?.title, "North Window Set")
        let request = await transport.requests.first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), TitleShelfClient.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        XCTAssertTrue(request?.url?.absoluteString.contains("page_size=20") == true)
        XCTAssertTrue(request?.url?.absoluteString.contains("/cgi/search.pl") == true)
    }

    func test_notFoundDoesNotRetry() async {
        let transport = ScriptedTransport()
        await transport.enqueue(data: Data(), status: 404)
        let client = client(transport, debounce: 0)
        let result = await client.lookup("missing")
        guard case .titles = result else {
            XCTFail("A miss falls back to the local shelf")
            return
        }
        let calls = await transport.calls
        XCTAssertEqual(calls, 1)
    }

    func test_transientRetriesOnce() async {
        let transport = ScriptedTransport()
        await transport.enqueue(error: URLError(.timedOut))
        let body = Data(#"{"docs":[{"title":"Late House Reel","key":"k"}]}"#.utf8)
        await transport.enqueue(data: body, status: 200)
        let client = client(transport, debounce: 0)
        let result = await client.lookup("late")
        guard case .titles(let titles) = result else {
            return XCTFail("retry should resolve")
        }
        XCTAssertEqual(titles.first?.title, "Late House Reel")
        let calls = await transport.calls
        XCTAssertEqual(calls, 2)
    }

    func test_malformedJSONFallsBack() async {
        let transport = ScriptedTransport()
        await transport.enqueue(data: Data("[]".utf8), status: 200)
        let client = client(transport, debounce: 0)
        let result = await client.lookup("aisle")
        guard case .titles(let titles) = result else {
            return XCTFail("malformed JSON is a handled miss")
        }
        XCTAssertFalse(titles.isEmpty)
        XCTAssertTrue(titles.contains { $0.title == "Aisle Four" })
    }

    func test_queryChangeCancelsTheStaleLookup() async {
        let transport = ScriptedTransport()
        let body = Data(#"{"docs":[{"title":"Cloak Bell","key":"cloak"}]}"#.utf8)
        await transport.enqueue(data: body, status: 200)
        let client = client(transport, debounce: 40_000_000)
        async let first = client.lookup("first-query")
        async let second = client.lookup("cloak")
        let leading = await first
        let trailing = await second
        XCTAssertEqual(leading, .cancelled)
        guard case .titles(let titles) = trailing else {
            return XCTFail("The later query should win")
        }
        XCTAssertTrue(titles.contains { $0.title == "Cloak Bell" })
    }

    private func client(_ transport: ScriptedTransport, debounce: UInt64) -> TitleShelfClient {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        return TitleShelfClient(
            transport: transport,
            cacheDirectory: folder,
            debounceNanoseconds: debounce
        )
    }
}

actor ScriptedTransport: HouseTransport {
    private(set) var requests: [URLRequest] = []
    private(set) var calls = 0
    private var steps: [Result<(Data, HTTPURLResponse), Error>] = []

    func enqueue(data: Data, status: Int) {
        let response = HTTPURLResponse(
            url: URL(fileURLWithPath: "/cgi/search.pl"),
            statusCode: status,
            httpVersion: nil,
            headerFields: nil
        )
        if let response {
            steps.append(.success((data, response)))
        } else {
            steps.append(.failure(ShelfFailure.status(status)))
        }
    }

    func enqueue(error: Error) {
        steps.append(.failure(error))
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        calls += 1
        requests.append(request)
        guard !steps.isEmpty else {
            throw ShelfFailure.status(599)
        }
        return try steps.removeFirst().get()
    }
}
