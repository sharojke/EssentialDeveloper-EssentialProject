@testable import EssentialApp
import EssentialFeed
import EssentialFeediOS
import XCTest

// swiftlint:disable force_cast
// swiftlint:disable force_unwrapping
// swiftlint:disable force_try

private class HTTPClientStub: HTTPClient {
    private class Task: HTTPClientTask {
        func cancel() {}
    }
    
    private let stub: (URL) -> HTTPClient.Result
    
    init(stub: @escaping (URL) -> HTTPClient.Result) {
        self.stub = stub
    }
    
    static func offline() -> HTTPClientStub {
        return HTTPClientStub(stub: { _ in .failure(NSError(domain: "offline", code: 0)) })
    }
    
    static func online(_ stub: @escaping (URL) -> (Data, HTTPURLResponse)) -> HTTPClientStub {
        return HTTPClientStub { url in .success(stub(url)) }
    }
    
    func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) -> HTTPClientTask {
        completion(stub(url))
        return Task()
    }
}

private class InMemoryFeedStore: FeedStore, FeedImageDataStore {
    static var empty: InMemoryFeedStore {
        InMemoryFeedStore()
    }
    
    private var feedCache: CachedFeed?
    private var feedImageDataCache: [URL: Data] = [:]
    
    func deleteCachedFeed(completion: @escaping FeedStore.DeletionCompletion) {
        feedCache = nil
        completion(.success(()))
    }
    
    func insert(
        feed: [LocalFeedImage],
        timestamp: Date,
        completion: @escaping FeedStore.InsertionCompletion
    ) {
        feedCache = CachedFeed(feed: feed, timestamp: timestamp)
        completion(.success(()))
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        completion(.success(feedCache))
    }
    
    func insert(
        _ data: Data,
        for url: URL,
        completion: @escaping (FeedImageDataStore.InsertionResult) -> Void
    ) {
        feedImageDataCache[url] = data
        completion(.success(()))
    }
    
    func retrieve(
        dataForURL url: URL,
        completion: @escaping (FeedImageDataStore.RetrievalResult) -> Void
    ) {
        completion(.success(feedImageDataCache[url]))
    }
}

final class FeedAcceptanceTests: XCTestCase {
    func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() {
        let feed = launch(
            httpClient: HTTPClientStub.online(response),
            store: InMemoryFeedStore.empty
        )
        
        XCTAssertEqual(feed.numberOfRenderedFeedImageViews, 2)
        XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData())
        XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData())
    }
    
    func test_onLaunch_displaysCachedFeedWhenCustomerHasNoConnectivity() {
    }
    
    func test_onLaunch_displaysEmptyFeedWhenCustomerHasNoConnectivityAndCache() {
    }
}

// MARK: - Helpers

private extension FeedAcceptanceTests {
    func launch(
        httpClient: HTTPClient = HTTPClientStub.offline(),
        store: FeedStore & FeedImageDataStore = InMemoryFeedStore.empty
    ) -> FeedViewController {
        let sut = SceneDelegate(httpClient: httpClient, store: store)
        sut.window = UIWindow()
        sut.configureWindow()
        
        let nav = sut.window?.rootViewController as? UINavigationController
        let feed = nav?.topViewController as! FeedViewController
        feed.simulateAppearance()
        return feed
    }
    
    func response(for url: URL) -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return (makeData(for: url), response)
    }
    
    func makeData(for url: URL) -> Data {
        switch url.absoluteString {
        case "http://image.com":
            return makeImageData()
            
        default:
            return makeFeedData()
        }
    }
    
    func makeImageData() -> Data {
        return UIImage.make(withColor: .red).pngData()!
    }
    
    func makeFeedData() -> Data {
        return try! JSONSerialization.data(
            withJSONObject: [
                "items": [
                    ["id": UUID().uuidString, "image": "http://image.com"],
                    ["id": UUID().uuidString, "image": "http://image.com"]
                ]
            ]
        )
    }
}

// swiftlint:enable force_cast
// swiftlint:enable force_unwrapping
// swiftlint:enable force_try
